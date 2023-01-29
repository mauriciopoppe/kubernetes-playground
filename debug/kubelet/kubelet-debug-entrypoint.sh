#!/bin/bash

set -euo pipefail

install() {
  # setup systemd kubelet-debug.service unit
  systemd=/etc/systemd/system
  mkdir -p "${systemd}/kubelet-debug.service.d"
  cp $CDEBUG_WORKSPACE/app/kubelet-debug.service "${systemd}"
  cp $CDEBUG_WORKSPACE/app/10-kubeadm.conf "${systemd}/kubelet-debug.service.d/10-kubeadm.conf"
  cp $CDEBUG_WORKSPACE/app/conf.kubernetes "${systemd}/kubelet-debug.service.d/conf.kubernetes"

  # copy kubelet to a debug file if it doesn't exist already
  if [[ ! -f /usr/bin/kubelet-debug ]]; then
    cp /usr/bin/kubelet /usr/bin/kubelet-debug
  fi

  # copy dlv if not already there
  if [[ ! -f /usr/bin/dlv ]]; then
    cp $CDEBUG_WORKSPACE/app/bin/dlv /usr/bin/dlv
  fi

  # start kubelet-debug unit and disable kubelet unit
  systemctl daemon-reload
  systemctl disable kubelet && systemctl stop kubelet
  systemctl enable kubelet-debug && systemctl start kubelet-debug
}

restore() {
  # restore kubelet systemd unit
  systemctl disable kubelet-debug && systemctl stop kubelet-debug
  systemctl enable kubelet && systemctl start kubelet
}

install
trap restore exit

bash
