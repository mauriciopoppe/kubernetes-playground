# Attach detach controller

## Summary

The Attach/Detach controller implements a controller to manage volume attach and detach operations.

NOTE: this analysis assumes that CSIMigration is turned on, therefore the paths that use the intree
plugins are not part of this analysis (like the intreeToCSITranslator).

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

```
// This custom indexer will index pods by its PVC keys. Then we don't need
// to iterate all pods every time to find pods whichereference given PVC.
```

## Run `func (adc *attachDetachController) Run`

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

```
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

```
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

```
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

It follows the common pattern for reconcilers `wait.Until(fn, 100ms, stop)`, fn is `func (rc *reconciler) reconcile()`.

`reconcile`
