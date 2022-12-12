# PV Controller

Controlls the binding of a PVC to a PV and from a PV to a PVC.

## kube-controller-manager setup

Read the doc /docs/kube-controller-manager.md

## Volume Dynamic Provisioning (Pod + PVC + StorageClass with volumeBindingMode Immediate)

- :syncClaim triggered, the PVC doesn't have the pv.kubernetes.io/bind-completed annotation set therefore it's unbound, call :syncUnboundClaim
- pkg/controller/volume/persistentvolume/pv_controller.go:syncUnboundClaim
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L333 detects an unbound PVC (an unbound PVC is one without the
  annotation pv.kubernetes.io/bind-completed)
- In pv_controller.go:syncUnboundClaim if pvc.Spec.VolumeName is empty it means that the PVC doesn't have a preprovisioned PV to attach to, we try to find a volume that's the best
  match for the claim. Let's assume that there's no PV, pv_controller.go:syncUnboundClaim needs to retry but first let's check if the PVC has a storageClassName (it does), so we
  call pkg/controller/volume/persistentvolume/pv_controller.go:provisionClaim
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L1531 to reach out to the external plugin in
  pkg/controller/volume/persistentvolume/pv_controller.go:provisionClaimOperationExternal
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L1783 which will set the annotation
  `"volume.kubernetes.io/storage-provisioner" = class.Provisioner` on the PVC.
- The external-provisioner sidecar (through the sig-storage-lib-external-provisioner dependency) detects a change in the PVC in
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/controller.go#L932
  which after some checks calls sig-storage-lib-external-provisioner/v8/controller/controller.go:shouldProvision
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/controller.go#L1056,
  this method checks if the the PVC has the annotation `volume.kubernetes.io/storage-provisioner` (it does), so it calls :provisionClaimOperation
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/controller.go#L1063
  which in turn calls the ctrl.provision.Provision method of the provisioner impl
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/controller.go#L1404
  (the Provisioner method is in pkg/controller/controller.go) which makes the CSI CreateVolume request
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b/pkg/controller/controller.go#L783, with the CSI CreateVolume response it's able to build a PV object
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/pkg/controller/controller.go#L862 and return it back to the
  ctrl.provision.Provision call, next it sets the PV claimRef field to be the PVC and the PV finalizer, finally it stores the volume with the call
  ctrl.volumeStore.StoreVolume(claim, volume)
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/controller.go#L1457
  which under the hood makes the request to the kube-api server in
  https://github.com/kubernetes-csi/external-provisioner/blob/014be4a50b20f7e95da699097e28570a4e22e1d3/vendor/sigs.k8s.io/sig-storage-lib-external-provisioner/v8/controller/volume_store.go#L155,
  at this point the PV is created and part of the kube-apiserver.
- Back in the PV controller, another run of pv_controller.go:syncUnboundClaim
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L333 detects an unbound PVC (an unbound PVC is one without the
  annotation pv.kubernetes.io/bind-completed), this time there's a PV that matches the PVC request
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L381 and call ctrl.bind(pv, pvc)
  https://github.com/kubernetes/kubernetes/blob/v1.25.0/pkg/controller/volume/persistentvolume/pv_controller.go#L1056 which
  - Binds the PV to a PVC (sets PV.Spec.ClaimRef = ref(PVC) and sets the bound-by-controller annotation on the PV)
  - Set the PV status to Bound
  - Binds a PVC to a PV (PVC.Spec.VolumeName = PV.Name and sets the bound-by-controller annotation in the PVC)
  - Sets the PVC status to Bound
