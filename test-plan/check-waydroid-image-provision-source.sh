#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu

script=$(dirname "$0")/../recipes-support/waydroid/waydroid/waydroid-image-provision
sh -n "$script"

release_guard=$(grep -nF 'if [ -r "${release_config}" ] && [ -s "${config}" ]' "$script" | cut -d: -f1)
fallback_boundary=$(grep -nF '# Existing machines retain the proven rolling-channel behaviour' "$script" | cut -d: -f1)
writable_pair_guard=$(grep -nF 'if [ -s "${images_dir}/system.img" ] && [ -s "${images_dir}/vendor.img" ]; then' "$script" | cut -d: -f1)

test -n "$release_guard"
test -n "$fallback_boundary"
test -n "$writable_pair_guard"
test "$release_guard" -lt "$fallback_boundary"
test "$writable_pair_guard" -gt "$fallback_boundary"
echo 'Waydroid immutable-release guard precedes writable-image fallback'
