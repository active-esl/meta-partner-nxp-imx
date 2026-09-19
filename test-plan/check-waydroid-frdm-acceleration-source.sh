#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
files="$repo/recipes-support/waydroid/waydroid"
recipe="$repo/recipes-support/waydroid/waydroid.bbappend"
prepare="$files/waydroid-frdm-prepare"
service="$files/waydroid-frdm-container.service"
apparmor_patch="$files/0004-apparmor-allow-android-resource-cache.patch"

sh -n "$prepare"
grep -Fqx 'ExecStartPre=/usr/libexec/waydroid-frdm-prepare' "$service"
grep -Fq 'file://waydroid-frdm-prepare' "$recipe"
grep -Fq 'file://0004-apparmor-allow-android-resource-cache.patch' "$recipe"
grep -Fq 'replace_property ro.hardware.egl mali' "$prepare"
grep -Fq 'replace_property ro.hardware.vulkan mali' "$prepare"
grep -Fq 'remove_property debug.stagefright.ccodec' "$prepare"
grep -Fq 'dev/dma_heap/reserved-uncached' "$prepare"
grep -Fq 'dev/dma_heap/system-uncached' "$prepare"
grep -Fq '/data/resource-cache/** r,' "$apparmor_patch"

echo 'FRDM Waydroid acceleration source check passed'
