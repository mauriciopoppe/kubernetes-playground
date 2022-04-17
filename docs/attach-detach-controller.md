# Attach detach controller

## Summary

The Attach/Detach controller implements a controller to manage volume attach and detach operations.

NOTE: this analysis assumes that CSIMigration is turned on, therefore the paths that use the intree
plugins are not part of this analysis (like the intreeToCSITranslator).

**Setup**:

`func NewAttachDetachController(` is initialized with many shared informers for Kinds like: Pod, Node, PVC,
PV, CSINode, CSIDriver, VolumeAttachment, an instance of `attachDetachController` is created with listers
and informers for the above Kinds, it also has a `workqueue` for PVCs.

There are 4 important objects created in the setup that are the core of the controller:

- `DesiredStateOfTheWorld`
- `ActualStateOfTheWorld`
- `Reconciler`
- `DesiredStateOfTheWorldPopulator`

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
// to iterate all pods every time to find pods which reference given PVC.
```
