#!/bin/sh
# Download one matched, fail-closed FRDM-IMX95 programming artifact set.

set -eu

usage() {
    echo "usage: $0 FACTORY TARGET OUTPUT_DIR" >&2
    exit 2
}

[ "$#" -eq 3 ] || usage
factory=$1
target=$2
output=$3

case "$target" in
    *[!0-9]*|'') echo "TARGET must be numeric" >&2; exit 2 ;;
esac

command -v fioctl >/dev/null 2>&1 || { echo "fioctl is required" >&2; exit 1; }
[ ! -e "$output" ] || { echo "refusing existing output: $output" >&2; exit 1; }

machine=imx95-frdm-evk
image="lmp-factory-image-${machine}"
product_run=$machine
mfgtool_run="${machine}-mfgtools"

parent=$(dirname "$output")
base=$(basename "$output")
mkdir -p "$parent"
tmpdir=$(mktemp -d "${parent}/.${base}.tmp.XXXXXX")
cleanup() {
    [ -z "${tmpdir:-}" ] || rm -rf -- "$tmpdir"
}
trap cleanup EXIT HUP INT TERM

download() {
    remote=$1
    local_name=$2
    echo "Downloading ${remote}" >&2
    if ! fioctl targets artifacts -f "$factory" "$target" "$remote" >"${tmpdir}/${local_name}"; then
        echo "artifact download failed: ${remote}" >&2
        exit 1
    fi
    [ -s "${tmpdir}/${local_name}" ] || {
        echo "artifact is missing or empty: ${remote}" >&2
        exit 1
    }
}

download "${product_run}/${image}.wic.gz" "${image}.wic.gz"
download "${product_run}/other/${image}.manifest" "${image}.manifest"
download "${product_run}/other/${image}.testdata.json" "${image}.testdata.json"
download "${product_run}/other/lmp-boot-firmware/imx-boot" "imx-boot-${machine}"
download "${product_run}/other/lmp-boot-firmware/u-boot.itb" "u-boot-${machine}.itb"
download "${product_run}/other/manifest.pinned.xml" manifest.pinned.xml
download "${mfgtool_run}/mfgtool-files-${machine}.tar.gz" "mfgtool-files-${machine}.tar.gz"

gzip -t "${tmpdir}/${image}.wic.gz" || { echo "invalid WIC gzip" >&2; exit 1; }
tar -tzf "${tmpdir}/mfgtool-files-${machine}.tar.gz" >/dev/null || {
    echo "invalid mfgtool archive" >&2
    exit 1
}

if ! grep -Eq '"IMXBOOT_TARGETS"[[:space:]]*:[[:space:]]*"flash_a55"' "${tmpdir}/${image}.testdata.json" ||
   ! grep -Eq '"IMXBOOT_TARGETS:imx95-frdm-evk"[[:space:]]*:[[:space:]]*"flash_a55"' "${tmpdir}/${image}.testdata.json"; then
    echo "product metadata does not select the FRDM flash_a55 container" >&2
    exit 1
fi

[ "$(stat -Lc '%s' "${tmpdir}/imx-boot-${machine}")" -le "$((0x400000))" ] || {
    echo "production imx-boot exceeds the 4 MiB bootloader slot" >&2
    exit 1
}
[ "$(stat -Lc '%s' "${tmpdir}/u-boot-${machine}.itb")" -le "$((0x1c0000))" ] || {
    echo "production U-Boot FIT exceeds the 0x1c0000-byte user-area slot" >&2
    exit 1
}

printf 'factory=%s\ntarget=%s\nproduct_run=%s\nmfgtool_run=%s\n' \
    "$factory" "$target" "$product_run" "$mfgtool_run" \
    >"${tmpdir}/TARGET-PROVENANCE"

(
    cd "$tmpdir"
    sha256sum \
        "${image}.wic.gz" \
        "${image}.manifest" \
        "${image}.testdata.json" \
        "imx-boot-${machine}" \
        "u-boot-${machine}.itb" \
        "mfgtool-files-${machine}.tar.gz" \
        manifest.pinned.xml \
        TARGET-PROVENANCE \
        > TARGET-SHA256SUMS
)

mv "$tmpdir" "$output"
tmpdir=
printf 'Matched target artifacts ready: %s\n' "$output"
printf 'Next: %s %s %s %s/programming-bundle\n' \
    "$(dirname "$0")/prepare-imx95-programming-bundle.sh" \
    "$output" "${output}/mfgtool-files-${machine}.tar.gz" "$output"
