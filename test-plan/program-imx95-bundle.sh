#!/usr/bin/env bash
# Guarded operator entry point for an assembled FRDM-IMX95 programming bundle.

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: ./program-imx95.sh check|program|bootloader|verify

  check    verify the bundle and require exactly one i.MX95 in serial-download mode
  program  program the complete Foundries image; no read-back verification
  bootloader  update both production boot sets; retain the WIC/root filesystem
  verify   run the separate, optional WIC read-back CRC
EOF
    exit 2
}

mode=${1:-}
case "$mode" in
    check|program|bootloader|verify) ;;
    *) usage ;;
esac

root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
machine=imx95-frdm-evk
bundle="${root}/mfgtool-files-${machine}"
uuu="${bundle}/uuu"
sums="${root}/PROGRAMMING-SHA256SUMS"

for file in "$uuu" "$sums" "$bundle/full_image.uuu" "$bundle/bootloader.uuu" "$bundle/verify_image.uuu"; do
    if [[ ! -s "$file" ]]; then
        printf 'missing or empty programming-bundle file: %s\n' "$file" >&2
        exit 1
    fi
done

printf 'Verifying matched programming artifacts...\n'
(
    cd "$root"
    sha256sum -c "$(basename "$sums")"
)

script="${bundle}/full_image.uuu"
if [[ "$mode" == verify ]]; then
    script="${bundle}/verify_image.uuu"
elif [[ "$mode" == bootloader ]]; then
    script="${bundle}/bootloader.uuu"
fi
"$uuu" -dry "$script" >/dev/null

device_output=$("$uuu" -lsusb 2>&1)
printf '%s\n' "$device_output"

# MX95 BootROM identities from NXP libuuu: SDPS 1fc9:015c and 1fc9:015d.
# https://github.com/nxp-imx/mfgtools/blob/master/libuuu/config.cpp
mx95_lines=$(printf '%s\n' "$device_output" |
    awk 'toupper($0) ~ /MX95/ && toupper($0) ~ /SDPS:/ &&
         toupper($0) ~ /0X1FC9/ && toupper($0) ~ /0X015[CD]/')
mx95_count=$(printf '%s\n' "$mx95_lines" | awk 'NF { count++ } END { print count + 0 }')

if [[ "$mx95_count" -ne 1 ]]; then
    printf '%s\n' \
        'Refusing to run: expected exactly one MX95 SDPS device (1fc9:015c or 1fc9:015d).' \
        'Power off, set FRDM SW1-1 OFF / SW1-2 ON, connect USB1 J3, then power on.' >&2
    exit 3
fi

if [[ "$mode" == check ]]; then
    printf 'PASS: matched bundle and exactly one i.MX95 serial-download device are ready.\n'
    exit 0
fi

if pgrep -x uuu >/dev/null 2>&1; then
    printf 'Refusing to run while another uuu process is active.\n' >&2
    exit 4
fi

mkdir -p "${root}/logs"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log="${root}/logs/uuu-${mode}-${machine}-${stamp}.log"

printf 'Starting %s with %s\n' "$mode" "$script"
printf 'UUU transcript: %s\n' "$log"
cd "$root"
set +e
"$uuu" "$script" 2>&1 | tee "$log"
uuu_status=${PIPESTATUS[0]}
set -e

printf 'UUU exit code: %s\n' "$uuu_status" | tee -a "$log"
printf 'UUU log bytes: %s\n' "$(wc -c < "$log")" | tee -a "$log"
exit "$uuu_status"
