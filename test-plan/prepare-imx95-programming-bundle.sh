#!/bin/sh
# Assemble and validate a matched FRDM-IMX95 UUU programming directory.

set -eu

usage() {
    echo "usage: $0 PRODUCT_DEPLOY_DIR MFGTOOL_ARCHIVE OUTPUT_DIR" >&2
    exit 2
}

[ "$#" -eq 3 ] || usage
deploy=$1
archive=$2
output=$3
helper_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
operator="${helper_dir}/program-imx95-bundle.sh"

machine=imx95-frdm-evk
image="lmp-factory-image-${machine}"
bundle_dir="mfgtool-files-${machine}"

for file in \
    "${deploy}/${image}.wic.gz" \
    "${deploy}/${image}.manifest" \
    "${deploy}/${image}.testdata.json" \
    "${deploy}/imx-boot-${machine}" \
    "${deploy}/u-boot-${machine}.itb" \
    "$archive" \
    "$operator"; do
    [ -s "$file" ] || { echo "missing or empty: $file" >&2; exit 1; }
done

boot_target=$(readlink "${deploy}/imx-boot-${machine}" 2>/dev/null || true)
case "$boot_target" in
    *flash_a55*) ;;
    *) echo "production imx-boot does not resolve to flash_a55: ${boot_target:-not a symlink}" >&2; exit 1 ;;
esac

[ ! -e "$output" ] || { echo "refusing existing output: $output" >&2; exit 1; }
parent=$(dirname "$output")
base=$(basename "$output")
mkdir -p "$parent"
tmpdir=$(mktemp -d "${parent}/.${base}.tmp.XXXXXX")
cleanup() {
    [ -z "${tmpdir:-}" ] || rm -rf -- "$tmpdir"
}
trap cleanup EXIT HUP INT TERM

cp -L "${deploy}/${image}.wic.gz" "$tmpdir/"
cp -L "${deploy}/${image}.manifest" "$tmpdir/"
cp -L "${deploy}/${image}.testdata.json" "$tmpdir/"
cp -L "${deploy}/imx-boot-${machine}" "$tmpdir/"
cp -L "${deploy}/u-boot-${machine}.itb" "$tmpdir/"
cp -L "$archive" "${tmpdir}/mfgtool-files-${machine}.tar.gz"
cp -L "$operator" "${tmpdir}/program-imx95.sh"
chmod 0755 "${tmpdir}/program-imx95.sh"
tar -xzf "${tmpdir}/mfgtool-files-${machine}.tar.gz" -C "$tmpdir"

bundle="${tmpdir}/${bundle_dir}"
for file in \
    "$bundle/uuu" \
    "$bundle/full_image.uuu" \
    "$bundle/verify_image.uuu" \
    "$bundle/imx-boot-mfgtool" \
    "$bundle/u-boot-mfgtool.itb"; do
    [ -s "$file" ] || { echo "incomplete mfgtool archive: $file" >&2; exit 1; }
done

if cmp -s "$bundle/imx-boot-mfgtool" "${tmpdir}/imx-boot-${machine}"; then
    echo "unsafe bundle: recovery and production imx-boot are identical" >&2
    exit 1
fi
if cmp -s "$bundle/u-boot-mfgtool.itb" "${tmpdir}/u-boot-${machine}.itb"; then
    echo "unsafe bundle: recovery and production U-Boot FIT are identical" >&2
    exit 1
fi

if ! "$bundle/uuu" -lsusb 2>&1 | grep -Fq 'libuuu_1.5.201'; then
    echo "unsafe bundle: UUU cannot parse i.MX95 AHAB v2 plus V2X containers" >&2
    exit 1
fi

if ! grep -Fq 'SDPS: boot -f imx-boot-mfgtool' "$bundle/full_image.uuu" ||
   ! grep -Fq 'SDPV: write -f imx-boot-mfgtool -skipspl' "$bundle/full_image.uuu" ||
   ! grep -Fq "write -f ../${image}.wic.gz/*" "$bundle/full_image.uuu" ||
   ! grep -Fq 'flash bootloader_s ../imx-boot-imx95-frdm-evk' "$bundle/full_image.uuu" ||
   ! grep -Fq 'flash bootloader2_s ../u-boot-imx95-frdm-evk.itb' "$bundle/full_image.uuu"; then
    echo "unsafe bundle: full_image.uuu does not retain the MX95 and Foundries flows" >&2
    exit 1
fi
if ! grep -Fq 'SDPS: boot -f imx-boot-mfgtool' "$bundle/verify_image.uuu" ||
   ! grep -Fq 'SDPV: write -f imx-boot-mfgtool -skipspl' "$bundle/verify_image.uuu" ||
   ! grep -Fq "crc -f ../${image}.wic.gz/*" "$bundle/verify_image.uuu" ||
   ! grep -Fq -- '-skip 0x400000 -seek 0x400000' "$bundle/verify_image.uuu"; then
    echo "unsafe bundle: optional verification or MX95 boot staging is invalid" >&2
    exit 1
fi

(
    cd "$tmpdir"
    "./${bundle_dir}/uuu" -dry "./${bundle_dir}/full_image.uuu" >/dev/null
    "./${bundle_dir}/uuu" -dry "./${bundle_dir}/verify_image.uuu" >/dev/null
    sha256sum \
        "${image}.wic.gz" \
        "${image}.manifest" \
        "${image}.testdata.json" \
        "imx-boot-${machine}" \
        "u-boot-${machine}.itb" \
        "mfgtool-files-${machine}.tar.gz" \
        "program-imx95.sh" \
        "${bundle_dir}/uuu" \
        "${bundle_dir}/full_image.uuu" \
        "${bundle_dir}/verify_image.uuu" \
        "${bundle_dir}/imx-boot-mfgtool" \
        "${bundle_dir}/u-boot-mfgtool.itb" \
        > PROGRAMMING-SHA256SUMS
)

mv "$tmpdir" "$output"
tmpdir=

printf 'Programming bundle ready: %s\n' "$output"
printf 'Preflight:\n  cd %s && ./program-imx95.sh check\n' "$output"
printf 'Program (no read-back):\n  cd %s && ./program-imx95.sh program\n' "$output"
printf 'Optional verification:\n  cd %s && ./program-imx95.sh verify\n' "$output"
