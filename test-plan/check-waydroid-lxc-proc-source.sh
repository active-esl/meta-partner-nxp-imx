#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

recipe="$(dirname "$0")/../recipes-support/waydroid/waydroid.bbappend"
config_fixture="$(mktemp)"
trap 'rm -f -- "${config_fixture}"' EXIT

# Exercise the exact shell helper used by both R16 board-specific do_install
# overrides, without invoking a full Yocto image build.
source <(sed -n '/^configure_waydroid_lxc_proc() {$/,/^}$/p' "${recipe}")
bbfatal() { printf '%s\n' "$*" >&2; return 1; }

printf '%s\n' 'lxc.mount.auto = cgroup:ro sys:ro proc' > "${config_fixture}"
configure_waydroid_lxc_proc "${config_fixture}"
grep -qx 'lxc.mount.auto = cgroup:ro sys:ro' "${config_fixture}"
grep -qx 'lxc.mount.entry = proc proc proc rw,remount,nodev,nosuid,noexec,relatime,hidepid=2,gid=3009 0 0' "${config_fixture}"
grep -qx 'lxc.mount.entry = proc/sys proc/sys proc ro,bind,relative 0 0' "${config_fixture}"
grep -qx 'lxc.mount.entry = proc/sys/net proc/sys/net proc rw,bind,relative 0 0' "${config_fixture}"
grep -qx 'lxc.mount.entry = proc/sysrq-trigger proc/sysrq-trigger proc ro,bind,relative 0 0' "${config_fixture}"
! grep -q 'lxc.mount.auto = .* proc' "${config_fixture}"
[[ "$(grep -c '^lxc.mount.entry = ' "${config_fixture}")" == 4 ]]

if configure_waydroid_lxc_proc "${config_fixture}" 2>/dev/null; then
    echo 'unexpectedly accepted an already-modified LXC template' >&2
    exit 1
fi
echo 'Waydroid LXC proc source check passed'
