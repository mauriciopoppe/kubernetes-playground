#!/bin/bash

set -euo pipefail

install() {
  # setup systemd containerd-debug.service unit
  systemd=/etc/systemd/system
  mkdir -p "${systemd}/containerd-debug.service.d"
  cp $CDEBUG_ROOTFS/app/containerd-debug.service "${systemd}"

  # copy dlv if not already there
  cp $CDEBUG_ROOTFS/app/bin/dlv /usr/bin/dlv

  # copy tooling (grcat)
  cp $CDEBUG_ROOTFS/app/bin/grcat /usr/bin/grcat
  cp $CDEBUG_ROOTFS/app/bin/grc /usr/bin/grc

  if ! command -v python3 &> /dev/null; then
    apt update && apt install -y python3
  fi

  # it's assumed that the containerd-debug binary will be replaced
  # later with a version of the containerd compiled in debug mode.
  #
  # start containerd-debug unit and disable containerd unit
  systemctl daemon-reload
  systemctl disable containerd && systemctl stop containerd
  systemctl enable containerd-debug && systemctl start containerd-debug

  # Success message
  (tput setaf 2; \
    echo "kind-worker patched with new containerd!"; \
    echo "next step: copy the containerd binary compiled with debug symbols to TODO"; \
    echo ""; \
    echo "Keep this terminal alive while you're on your debugging session."; \
    tput sgr0)
}

restore() {
  # restore containerd systemd unit
  systemctl disable containerd-debug && systemctl stop containerd-debug
  systemctl enable containerd && systemctl start containerd
}

install
trap restore exit

# start /bin/bash
/bin/bash
