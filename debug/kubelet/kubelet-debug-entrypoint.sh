#!/bin/bash

set -euo pipefail

install() {
  # setup systemd kubelet-debug.service unit
  systemd=/etc/systemd/system
  mkdir -p "${systemd}/kubelet-debug.service.d"
  cp $CDEBUG_ROOTFS/app/kubelet-debug.service "${systemd}"
  cp $CDEBUG_ROOTFS/app/10-kubeadm.conf "${systemd}/kubelet-debug.service.d/10-kubeadm.conf"
  cp $CDEBUG_ROOTFS/app/conf.kubernetes "${systemd}/kubelet-debug.service.d/conf.kubernetes"

  # copy dlv if not already there
  cp $CDEBUG_ROOTFS/app/bin/dlv /usr/bin/dlv

  # copy tooling (grcat)
  cp $CDEBUG_ROOTFS/app/bin/grcat /usr/bin/grcat
  cp $CDEBUG_ROOTFS/app/bin/grc /usr/bin/grc

  if ! command -v python3 &> /dev/null; then
    apt update && apt install -y python3
  fi

  # it's assumed that the kubelet-debug binary will be replaced
  # later with a version of the kubelet compiled in debug mode.
  #
  # start kubelet-debug unit and disable kubelet unit
  systemctl daemon-reload
  systemctl disable kubelet && systemctl stop kubelet
  systemctl enable kubelet-debug && systemctl start kubelet-debug

  # Success message
  (tput setaf 2; \
    echo "kind-worker patched with new kubelet!"; \
    echo "next step: copy the kubelet binary compiled with debug symbols to /usr/bin/kubelet-debug"; \
    echo ""; \
    echo "Keep this terminal alive while you're on your debugging session."; \
    tput sgr0)
}

restore() {
  # restore kubelet systemd unit
  systemctl disable kubelet-debug && systemctl stop kubelet-debug
  systemctl enable kubelet && systemctl start kubelet
}

install
trap restore exit

# start /bin/bash
/bin/bash
