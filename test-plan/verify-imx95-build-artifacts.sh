#!/bin/sh
# Verify the publishable FRDM-IMX95 Factory artifacts and selected packages.

set -u

usage() {
    echo "usage: $0 DEPLOY_DIR [--product]" >&2
    exit 2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi
deploy=$1
product=0
if [ "$#" -eq 2 ]; then
    [ "$2" = "--product" ] || usage
    product=1
fi

machine=imx95-frdm-evk
image="lmp-factory-image-${machine}"
manifest="${deploy}/${image}.manifest"
pass=0
fail=0

ok() {
    printf 'PASS: %s\n' "$1"
    pass=$((pass + 1))
}

bad() {
    printf 'FAIL: %s\n' "$1" >&2
    fail=$((fail + 1))
}

need_file() {
    if [ -s "${deploy}/$1" ]; then ok "$1 is non-empty"; else bad "$1 is missing or empty"; fi
}

need_dir() {
    if [ -d "${deploy}/$1" ]; then ok "$1 exists"; else bad "$1 is missing"; fi
}

need_package() {
    package=$1
    if [ -s "$manifest" ] && awk -v p="$package" '$1 == p { found=1 } END { exit !found }' "$manifest"; then
        ok "manifest selects $package"
    else
        bad "manifest does not select $package"
    fi
}

for suffix in manifest ota-ext4.gz ota.tar.xz tar.zst testdata.json wic wic.bmap wic.gz; do
    need_file "${image}.${suffix}"
done

need_file "imx-boot-${machine}"
boot_target=$(readlink "${deploy}/imx-boot-${machine}" 2>/dev/null || true)
case "$boot_target" in
    *flash_a55*) ok "production imx-boot resolves to flash_a55" ;;
    *) bad "production imx-boot target is not flash_a55: ${boot_target:-not a symlink}" ;;
esac

need_file "u-boot-${machine}.itb"
need_file "lmp-boot-firmware/imx-boot"
need_file "lmp-boot-firmware/u-boot.itb"
need_file arm-trusted-firmware.bin
need_file m33_image-mx95evk.bin
need_file oei-m33-ddr.bin
need_file tee.bin
need_dir ostree_repo
need_file "ostree_repo/refs/heads/${machine}"

ostree_ref=$(tr -d '\n' <"${deploy}/ostree_repo/refs/heads/${machine}" 2>/dev/null || true)
case "$ostree_ref" in
    *[!0-9a-f]*|'') bad "OSTree ref is not a hexadecimal checksum: ${ostree_ref:-empty}" ;;
    *)
        if [ "${#ostree_ref}" -eq 64 ]; then ok "OSTree ref is a 64-character checksum"; else bad "OSTree ref has ${#ostree_ref} characters"; fi
        ;;
esac

for package in \
    firmware-ele-imx \
    firmware-nxp-wifi-nxpiw612-sdio \
    kernel-module-nxp-wlan \
    resize-helper; do
    need_package "$package"
done

if [ "$product" -eq 1 ]; then
    for package in \
        packagegroup-nxp-otbr \
        waydroid \
        weston \
        zigbee-rcp-apps \
        zigbee-rcp-sdk; do
        need_package "$package"
    done
fi

printf '\nArtifact fingerprints\n'
for artifact in \
    "${image}.wic.gz" \
    "imx-boot-${machine}" \
    "u-boot-${machine}.itb" \
    "${image}.manifest"; do
    [ -s "${deploy}/${artifact}" ] && sha256sum "${deploy}/${artifact}"
done

printf '\nSummary: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
