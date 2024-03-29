# Attach detach controller

## Summary

The Attach/Detach controller manages volume attach and detach operations.

NOTE: this analysis assumes that CSIMigration is turned on, therefore the paths that use the intree
plugins are not part of this analysis (like the intreeToCSITranslator).

The attach/detach controller is initialized in the kube-controller-manager (kcm), the kcm initializes
many builtin controllers in [NewControllerInitializers](https://github.com/kubernetes/kubernetes/blob/132f29769dfecfc808adc58f756be43171054094/cmd/kube-controller-manager/app/controllermanager.go#L450), the function [`startAttachDetachController`](https://github.com/kubernetes/kubernetes/blob/132f29769dfecfc808adc58f756be43171054094/cmd/kube-controller-manager/app/core.go#L299)
is the starting point.

## Setup `func NewAttachDetachController(`

`func NewAttachDetachController(` is initialized with many shared informers for Kinds like: Pod, Node, PVC,
PV, CSINode, CSIDriver, VolumeAttachment, an instance of `attachDetachController` is created with listers
and informers for the above Kinds, it also has a `workqueue` for PVCs.

There are 4 important objects created in the setup that are the core of the controller:

- `DesiredStateOfTheWorld` (abbreviated as DSW)
- `ActualStateOfTheWorld` (abbreviated as ASW)
- `Reconciler`
- `DesiredStateOfTheWorldPopulator` (abbreviated as DSWP)

There are additional objects that help update the status of objects:

- `NodeStatusUpdater`
- `Broadcaster`

During the setup we add event handlers for the informers

- pod add, update and delete callbacks
- node add, update, delete callbacks
- pvc add and update callbacks

In addition there's an indexer by pvc in the pod informer, the comment explains it:

```go
// This custom indexer will index pods by its PVC keys. Then we don't need
// to iterate all pods every time to find pods whichereference given PVC.
```

## `func (adc *attachDetachController) Run`

Wait for all the informers to sync, populate the actual state of the world, and the desired
state of the world, start the reconciler in a goroutine, the desired state of the world populator
in another goroutine and wait for PVC items to come out of the workqueue.

To populate the ASW we list the nodes in the cluster and gather all the
volumes attached by checking the `node.Status.VolumesAttached`, in the ASW we mark
a volume as attached if it's seen here, we also process the list of volumes in use in
`node.Status.VolumesInUse`, a volume is marked as *mounted* if it's both attached and in use i.e.
if it's in both lists, next, we add the node to the DSW in the `dsw.nodesManaged` field.

The last step of the ASW population is to process the VolumeAttachments (VA), a volume attachment
is the intent to attach a volume, the comment in the `processVolumeAttachment` function
explains it well:

```go
// For each VA object, this function checks if its present in the ASW.
// If not, adds the volume to ASW as an "uncertain" attachment.
// In the reconciler, the logic checks if the volume is present in the DSW;
//   if yes, the reconciler will attempt attach on the volume;
//   if not (could be a dangling attachment), the reconciler will detach this volume.
```

To populate the DSW we list pods and iterate over them, for every pod we determine the action `addToVolume` to
take for the pod and its volumes which is to either add them to the DSWP or remove them from the DSW,
to do so, we iterate over the `pod.Spec.Volumes`, we create a `VolumeSpec` (a mutable copy of the existing
one with any PVC dereferenced to get its PV)

If `addToVolume` is true then we add the pod to the list of pods that reference the specified volume
(if it wasn't already added before), the volume to attach is added to the DSW as follows, read
`func (dsw *desiredStateOfWorld) AddPod`

```go
// add volume to the DSW
volumeObj, volumeExists := nodeObj.volumesToAttach[volumeName]
if !volumeExists {
  volumeObj = volumeToAttach{
    multiAttachErrorReported: false,
    volumeName:               volumeName,
    spec:                     volumeSpec,
    scheduledPods:            make(map[types.UniquePodName]pod),
  }
  dsw.nodesManaged[nodeName].volumesToAttach[volumeName] = volumeObj
}
// add pod to the DSW (if it didn't exist before)
if _, podExists := volumeObj.scheduledPods[podName]; !podExists {
  dsw.nodesManaged[nodeName].volumesToAttach[volumeName].scheduledPods[podName] =
    pod{
      podName: podName,
      podObj:  podToAdd,
    }
}
```

If `addToVolume` is false then we remove it with the DSW with the reverse operation of above,
read `func (dsw *desiredStateOfWorld) DeletePod`

```go
// remove the pod from the list of scheduled pods for the volume
delete(
  dsw.nodesManaged[nodeName].volumesToAttach[volumeName].scheduledPods,
  podName)

// the volume is only deleted once there are no references from Pods to it
if len(volumeObj.scheduledPods) == 0 {
  delete(
    dsw.nodesManaged[nodeName].volumesToAttach,
    volumeName)
}
```

Still in the populate DSW, after adding the pod and its volumes to the DSW we replace the
volumes specs in the ASW with the correct ones found in the pods, also the volumes in the pod
which are marked as attached, this is if `asw.attachedVolumes[volumeName].nodesAttachedTo[nodeName]`
exists and its `attachConfirmed` property is set to true (note a few volumes were marked as uncertain before using the VA objects) are marked as attached (read `MarkVolumeAsAttached > AddVolumeNode`), I believe
only its `devicePath` property is updated because it's already marked as attached.

## Reconciler `func (rc *reconciler) Run`

It follows the common pattern for reconcilers `wait.Until(fn, 100ms, stop)`, fn is `func (rc *reconciler) reconcile()`, the code simplifies to:

```go
func (rc *reconciler) reconcile() {
  detachASWAttachedVolumes()
  attachDSWVolumesToAttach()
}
```

`reconcile` handles detaches first, there are many interesting cases including
https://github.com/kubernetes/kubernetes/issues/93902, the code simplifies to:

```go
for _, attachedVolume := range ASW.GetAttachedVolumes() {
  if !DSW.VolumeExists(attachedVolume) {
    // lots of checks to make sure that the detach is safe
    // ...
    err := reconciler.attacherDetacher.DetachVolume(attachedVolume)
    if err != nil {
      // so that NodeStatusUpdater will add it back to the VolumeAttached list
      ASW.AddVolumeToReportAsAttached(attachedVolume)
    }
  }
}
```

`reconcile` handles attach next, the code simplifies to:

```go
for _, volumeToAttach := range DSW.GetVolumesToAttach() {
  // lots of checks to make sure that the attach is safe
  // ...
  err := reconciler.attacherDetacher.AttachVolume(volumeToAttach)
}
```

## DSWP `func (dswp *desiredStateOfWorldPopulator) Run`

The DSWP removes/adds the volumes found in pods to the DSW.

For the removal, it iterates over the pods added to the DSW and checks if the pod
is still available in the API server through the informer, if it's not in the informer
then it's deleted from the DSW.

For the addition, it lists all the pods in the informer and if it's not terminated
it iterates over all the `pod.Spec.Volumes` and adds the `<pod, volume>` to the DSW
