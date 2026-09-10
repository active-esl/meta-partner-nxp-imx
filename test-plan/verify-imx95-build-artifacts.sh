#!/bin/sh
# Verify the publishable FRDM-IMX95 Factory artifacts and selected packages.

set -u

usage() {
    echo "usage: $0 DEPLOY_DIR [--product] [--mfgtool] [--mfgtool-archive PATH]" >&2
    exit 2
}

if [ "$#" -lt 1 ]; then
    usage
fi
deploy=$1
shift
product=0
mfgtool=0
mfgtool_archive_arg=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --product)
            product=1
            shift
            ;;
        --mfgtool)
            mfgtool=1
            shift
            ;;
        --mfgtool-archive)
            [ "$#" -ge 2 ] || usage
            mfgtool=1
            mfgtool_archive_arg=$2
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

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

reject_package() {
    package=$1
    if [ -s "$manifest" ] && awk -v p="$package" '$1 == p { found=1 } END { exit !found }' "$manifest"; then
        bad "manifest unexpectedly selects $package"
    else
        ok "manifest does not select conflicting $package"
    fi
}

need_archive_member() {
    member=$1
    if tar -tzf "$mfgtool_archive" 2>/dev/null | grep -Fqx "$bundle_dir/$member"; then
        ok "mfgtool bundle contains $member"
    else
        bad "mfgtool bundle does not contain $member"
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
if [ -s "${deploy}/imx-boot-${machine}" ] &&
   [ "$(stat -Lc '%s' "${deploy}/imx-boot-${machine}")" -le "$((0x400000))" ]; then
    ok "production imx-boot fits the 4 MiB bootloader slot"
else
    bad "production imx-boot exceeds the 4 MiB bootloader slot"
fi
if [ -s "${deploy}/u-boot-${machine}.itb" ] &&
   [ "$(stat -Lc '%s' "${deploy}/u-boot-${machine}.itb")" -le "$((0x3a0000))" ]; then
    ok "production U-Boot FIT fits the 0x3a0000-byte bootloader2 slot"
else
    bad "production U-Boot FIT exceeds the 0x3a0000-byte bootloader2 slot"
fi
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
        gstreamer1.0-plugins-bad-kms \
        mdns \
        mlanutl \
        otbr-iwxxx \
        packagegroup-nxp-otbr \
        tayga \
        waydroid \
        weston \
        zigbee-rcp-apps \
        zigbee-rcp-sdk; do
        need_package "$package"
    done
    reject_package libnss-mdns
    reject_package otbr
fi

if [ "$mfgtool" -eq 1 ]; then
    if [ -n "$mfgtool_archive_arg" ]; then
        mfgtool_archive=$mfgtool_archive_arg
        if [ -s "$mfgtool_archive" ]; then
            ok "external mfgtool archive is non-empty"
        else
            bad "external mfgtool archive is missing or empty: $mfgtool_archive"
        fi
    else
        mfgtool_archive="${deploy}/mfgtool-files-${machine}.tar.gz"
        need_file "mfgtool-files-${machine}.tar.gz"
    fi
    bundle_dir="mfgtool-files-${machine}"

    for member in \
        README.md \
        bootloader.uuu \
        fitImage-imx95-frdm-evk-mfgtool \
        full_image.uuu \
        imx-boot-mfgtool \
        u-boot-mfgtool.itb \
        uuu \
        verify_image.uuu; do
        need_archive_member "$member"
    done

    tmpdir=$(mktemp -d) || exit 1
    trap 'rm -rf -- "$tmpdir"' EXIT HUP INT TERM
    if tar -xzf "$mfgtool_archive" -C "$tmpdir"; then
        bundle="${tmpdir}/${bundle_dir}"
        full_script="${bundle}/full_image.uuu"
        verify_script="${bundle}/verify_image.uuu"

        if "${bundle}/uuu" -lsusb 2>&1 | grep -Fq 'libuuu_1.5.201'; then
            ok "bundled UUU has AHAB v2 and V2X container parsing"
        else
            bad "bundled UUU is not the pinned i.MX95-safe 1.5.201 release"
        fi

        if grep -Fq 'SDPS: boot -f imx-boot-mfgtool' "$full_script" &&
           grep -Fq 'SDPV: write -f imx-boot-mfgtool -skipspl' "$full_script" &&
           grep -Fq 'SDPS: boot -f imx-boot-mfgtool' "$verify_script" &&
           grep -Fq 'SDPV: write -f imx-boot-mfgtool -skipspl' "$verify_script"; then
            ok "MX95 ROM and SPL stages consume one flash_all container"
        else
            bad "MX95 ROM or SPL stage does not use the NXP flash_all flow"
        fi

        if grep -Fq 'getvar partition-size:all' "$full_script" &&
           grep -Fq 'getvar partition-type:all' "$full_script" &&
           grep -Fq 'getvar partition-size:bootloader' "$full_script" &&
           grep -Fq 'getvar partition-size:bootloader2' "$full_script" &&
           grep -Fq 'getvar partition-size:bootloader_s' "$full_script" &&
           grep -Fq 'getvar partition-size:bootloader2_s' "$full_script" &&
           grep -Fq 'if @PARTITION-SIZE:BOOTLOADER@ != 0X400000 then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-TYPE:BOOTLOADER@ != RAW then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-SIZE:BOOTLOADER2@ != 0X3A0000 then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-TYPE:BOOTLOADER2@ != RAW then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-SIZE:BOOTLOADER_S@ != 0X400000 then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-TYPE:BOOTLOADER_S@ != RAW then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-SIZE:BOOTLOADER2_S@ != 0X3A0000 then ucmd false' "$full_script" &&
           grep -Fq 'if @PARTITION-TYPE:BOOTLOADER2_S@ != RAW then ucmd false' "$full_script" &&
           grep -Fq 'download -f ../imx-boot-imx95-frdm-evk' "$full_script" &&
           grep -Fq 'itest ${filesize} -le 400000' "$full_script" &&
           grep -Fq 'download -f ../u-boot-imx95-frdm-evk.itb' "$full_script" &&
           grep -Fq 'itest ${filesize} -le 3a0000' "$full_script" &&
           grep -Fq "flash -raw2sparse all ../${image}.wic.gz/*" "$full_script" &&
           grep -Fq 'flash bootloader ../imx-boot-imx95-frdm-evk' "$full_script" &&
           grep -Fq 'flash bootloader2 ../u-boot-imx95-frdm-evk.itb' "$full_script" &&
           grep -Fq 'flash bootloader_s ../imx-boot-imx95-frdm-evk' "$full_script" &&
           grep -Fq 'flash bootloader2_s ../u-boot-imx95-frdm-evk.itb' "$full_script"; then
            last_preflight=$(grep -nF 'itest ${filesize} -le 3a0000' "$full_script" | tail -n 1 | cut -d: -f1)
            first_write=$(grep -nF 'flash -raw2sparse all ' "$full_script" | head -n 1 | cut -d: -f1)
            if [ -n "$last_preflight" ] && [ -n "$first_write" ] && [ "$last_preflight" -lt "$first_write" ]; then
                ok "full_image.uuu asserts live slot and payload sizes before sparse-flashing the WIC plus both boot sets"
            else
                bad "full_image.uuu performs a persistent write before completing its i.MX95 preflight"
            fi
        else
            bad "full_image.uuu does not retain the complete Foundries programming flow"
        fi

        if grep -Fq "crc -f ../${image}.wic.gz/*" "$verify_script" &&
           grep -Fq -- '-skip 0x400000 -seek 0x400000' "$verify_script"; then
            ok "verify_image.uuu retains separate aligned WIC read-back"
        else
            bad "verify_image.uuu does not retain separate aligned WIC read-back"
        fi

        if cmp -s "${bundle}/imx-boot-mfgtool" "${deploy}/imx-boot-${machine}"; then
            bad "recovery and production imx-boot payloads are identical"
        else
            ok "recovery and production imx-boot payloads are distinct"
        fi
        if cmp -s "${bundle}/u-boot-mfgtool.itb" "${deploy}/u-boot-${machine}.itb"; then
            bad "recovery and production U-Boot FIT payloads are identical"
        else
            ok "recovery and production U-Boot FIT payloads are distinct"
        fi

        ln -s "${deploy}/${image}.wic.gz" "${tmpdir}/${image}.wic.gz"
        ln -s "${deploy}/imx-boot-${machine}" "${tmpdir}/imx-boot-${machine}"
        ln -s "${deploy}/u-boot-${machine}.itb" "${tmpdir}/u-boot-${machine}.itb"
        if "${bundle}/uuu" -dry "${full_script}" >/dev/null 2>&1 &&
           "${bundle}/uuu" -dry "${verify_script}" >/dev/null 2>&1; then
            ok "bundled UUU accepts programming and optional verification scripts"
        else
            bad "bundled UUU rejects a programming or verification script"
        fi
    else
        bad "mfgtool bundle cannot be extracted"
    fi
fi

printf '\nArtifact fingerprints\n'
for artifact in \
    "${image}.wic.gz" \
    "imx-boot-${machine}" \
    "u-boot-${machine}.itb" \
    "${image}.manifest" \
    "mfgtool-files-${machine}.tar.gz"; do
    [ -s "${deploy}/${artifact}" ] && sha256sum "${deploy}/${artifact}"
done

if [ "$mfgtool" -eq 1 ] && [ -s "$mfgtool_archive" ]; then
    sha256sum "$mfgtool_archive"
fi

printf '\nSummary: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
