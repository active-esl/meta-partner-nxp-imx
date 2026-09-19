#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
files="$repo/recipes-support/waydroid/waydroid"
recipe="$repo/recipes-support/waydroid/waydroid.bbappend"
prepare="$files/waydroid-frdm-prepare"
service="$files/waydroid-frdm-container.service"
session_service="$files/waydroid-frdm-session.service"
network_ready="$files/waydroid-frdm-network-ready"
network_script="$files/waydroid-net.sh"
apparmor_patch="$files/0004-apparmor-allow-android-resource-cache.patch"

sh -n "$prepare"
sh -n "$network_ready"
sh -n "$network_script"
grep -Fqx 'ExecStartPre=/usr/libexec/waydroid-frdm-prepare' "$service"
grep -Fqx 'Wants=docker.service' "$service"
grep -Fqx 'PartOf=docker.service' "$service"
grep -Fqx 'After=waydroid-image-provision.service dbus.service docker.service' "$service"
! grep -Fq 'ExecStartPost=/usr/libexec/waydroid-frdm-network-ready' "$service"
grep -Fqx 'ExecStartPost=/usr/libexec/waydroid-frdm-network-ready' "$session_service"
grep -Fqx 'TimeoutStartSec=180' "$session_service"
grep -Fq 'file://waydroid-frdm-prepare' "$recipe"
grep -Fq 'file://waydroid-frdm-network-ready' "$recipe"
grep -Fq 'file://0004-apparmor-allow-android-resource-cache.patch' "$recipe"
grep -Fq 'replace_property ro.hardware.egl mali' "$prepare"
grep -Fq 'replace_property ro.hardware.vulkan mali' "$prepare"
grep -Fq 'remove_property debug.stagefright.ccodec' "$prepare"
grep -Fq 'dev/dma_heap/reserved-uncached' "$prepare"
grep -Fq 'dev/dma_heap/system-uncached' "$prepare"
grep -Fq '/data/resource-cache/** r,' "$apparmor_patch"
grep -Fq 'IPTABLES_BIN="$(command -v iptables)"' "$network_script"
grep -Fq 'IP6TABLES_BIN="$(command -v ip6tables)"' "$network_script"
! sed -n '/^IPTABLES_BIN=/,/^fi$/p' "$network_script" | head -1 | grep -q iptables-legacy
grep -Fq 'mount -o remount,rw /proc/sys/net' "$network_ready"
grep -Fq "grep -q ' /proc/sys/net proc rw,' /proc/mounts" "$network_ready"

echo 'FRDM Waydroid acceleration source check passed'
