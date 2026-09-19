#!/usr/bin/env bash
# Guarded operator entry point for an assembled FRDM-IMX95 programming bundle.

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: ./program-imx95.sh check|program|bootloader|verify
       ./program-imx95.sh resume-fastboot MX95_ROM_SERIAL

  check    verify the bundle and require exactly one i.MX95 in serial-download mode
  program  program the complete Foundries image; no read-back verification
  bootloader  update both production boot sets; retain the WIC/root filesystem
  verify   run the separate, optional WIC read-back CRC
  resume-fastboot  finish full programming on the same MX95 already in Fastboot
EOF
    exit 2
}

mode=${1:-}
case "$mode" in
    check|program|bootloader|verify|resume-fastboot) ;;
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

# A ROM-to-Fastboot transition can leave UUU reporting exit 0 after only the
# SDPS command. The explicit recovery path uses only the FB commands from the
# checksum-verified full-image script, and is bound to the observed MX95 ROM
# serial so a shared 1fc9:0152 Fastboot PID cannot select an i.MX8 board.
if [[ "$mode" == resume-fastboot ]]; then
    expected_serial=${2:-}
    if [[ ! "$expected_serial" =~ ^[[:xdigit:]]{16}$ ]]; then
        printf 'resume-fastboot requires the 16-hex-digit MX95 ROM serial.\n' >&2
        exit 2
    fi
    expected_serial=${expected_serial^^}
    resume_script=$(mktemp --suffix=.uuu "${bundle}/.fb-resume.XXXXXX")
    trap 'rm -f -- "$resume_script"' EXIT
    awk '/^uuu_version / || /^FB(:|\[)/ { print }' "$script" > "$resume_script"
    script=$resume_script
fi

"$uuu" -dry "$script" >/dev/null
fb_total=$(grep -Ec '^FB(:|\[)' "$script")
if [[ "$fb_total" -lt 1 ]] || ! grep -Fqx 'FB: done' <(tail -n 1 "$script"); then
    printf 'Refusing script without a complete Fastboot stage: %s\n' "$script" >&2
    exit 2
fi

device_output=$("$uuu" -lsusb 2>&1)
printf '%s\n' "$device_output"

# MX95 BootROM identities from NXP libuuu: SDPS 1fc9:015c and 1fc9:015d.
# https://github.com/nxp-imx/mfgtools/blob/master/libuuu/config.cpp
mx95_lines=$(printf '%s\n' "$device_output" |
    awk 'toupper($0) ~ /MX95/ && toupper($0) ~ /SDPS:/ &&
         toupper($0) ~ /0X1FC9/ && toupper($0) ~ /0X015[CD]/')
mx95_count=$(printf '%s\n' "$mx95_lines" | awk 'NF { count++ } END { print count + 0 }')

if [[ "$mode" == resume-fastboot ]]; then
    fb_count=$(printf '%s\n' "$device_output" |
        awk -v serial="$expected_serial" 'toupper($0) ~ /FB:/ &&
             toupper($0) ~ /0X1FC9/ && toupper($0) ~ /0X0152/ &&
             toupper($0) ~ serial { count++ } END { print count + 0 }')
    if [[ "$fb_count" -ne 1 ]]; then
        printf 'Refusing resume: expected exactly one 1fc9:0152 Fastboot device with MX95 ROM serial %s.\n' "$expected_serial" >&2
        exit 3
    fi
elif [[ "$mx95_count" -ne 1 ]]; then
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
"$uuu" -v "$script" 2>&1 | tee "$log"
uuu_status=${PIPESTATUS[0]}
set -e

printf 'UUU exit code: %s\n' "$uuu_status" | tee -a "$log"
printf 'UUU log bytes: %s\n' "$(wc -c < "$log")" | tee -a "$log"
if [[ "$uuu_status" -ne 0 ]]; then
    exit "$uuu_status"
fi

# The non-verbose TUI can exit zero after SDPS alone, and its progress display
# is not a reliable log format. Verbose UUU emits one Start Cmd and Okay per
# completed command, including FB: done; require the complete FB command set.
fb_started=$(grep -ac '>Start Cmd:FB' "$log" || true)
commands_ok=$(grep -ac '>.*Okay (' "$log" || true)
if [[ "$fb_started" -ne "$fb_total" || "$commands_ok" -lt "$fb_total" ]] ||
   ! grep -aFq 'Start Cmd:FB: done' "$log" ||
   grep -aEq 'Failure[[:space:]]+[1-9]' "$log"; then
    printf 'ERROR: UUU exited zero without proof of all %s Fastboot commands and FB: done (started=%s, okay=%s); flash is NOT verified.\n' "$fb_total" "$fb_started" "$commands_ok" | tee -a "$log" >&2
    exit 5
fi

printf 'PASS: UUU completed all %s Fastboot commands and FB: done.\n' "$fb_total" | tee -a "$log"
