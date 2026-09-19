#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu

script=$(dirname "$0")/../recipes-support/waydroid/waydroid/waydroid-image-provision
release_config=$(dirname "$script")/waydroid-image-release.conf
sh -n "$script"

release_guard=$(grep -nF 'if [ -r "${release_config}" ] && [ -s "${config}" ]' "$script" | cut -d: -f1)
fallback_boundary=$(grep -nF '# Existing machines retain the proven rolling-channel behaviour' "$script" | cut -d: -f1)
writable_pair_guard=$(grep -nF 'if [ -s "${images_dir}/system.img" ] && [ -s "${images_dir}/vendor.img" ]; then' "$script" | cut -d: -f1)

test -n "$release_guard"
test -n "$fallback_boundary"
test -n "$writable_pair_guard"
test "$release_guard" -lt "$fallback_boundary"
test "$writable_pair_guard" -gt "$fallback_boundary"

# shellcheck disable=SC1090
. "$release_config"
test -n "${WAYDROID_IMAGE_RELEASE:-}"
case "$WAYDROID_IMAGE_BASE_URL" in
    https://*|http://192.168.68.55:8082/releases/*) ;;
    *) echo 'Waydroid release URL is neither HTTPS nor the private lab artifact service' >&2; exit 1 ;;
esac
for digest in \
    "$WAYDROID_SYSTEM_SHA256" \
    "$WAYDROID_VENDOR_SHA256" \
    "$WAYDROID_SOURCE_LOCK_SHA256"
do
    printf '%s\n' "$digest" | grep -Eq '^[0-9a-f]{64}$'
done
echo 'Waydroid immutable-release guard precedes writable-image fallback'
