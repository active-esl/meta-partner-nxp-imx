#!/bin/sh
# Reject a production U-Boot configuration that cannot consume the Foundries
# bootloader2 FIT layout programmed into eMMC boot0/boot1.

set -u

if [ "$#" -ne 1 ] || [ ! -s "$1" ]; then
    echo "usage: $0 PATH_TO_PRODUCTION_UBOOT_DOT_CONFIG" >&2
    exit 2
fi

config=$1
pass=0
fail=0

require_enabled() {
    symbol=$1
    if grep -Fqx "${symbol}=y" "$config"; then
        printf 'PASS: %s is enabled\n' "$symbol"
        pass=$((pass + 1))
    else
        printf 'FAIL: %s is not enabled\n' "$symbol" >&2
        fail=$((fail + 1))
    fi
}

require_value() {
    assignment=$1
    if grep -Fqx "$assignment" "$config"; then
        printf 'PASS: %s\n' "$assignment"
        pass=$((pass + 1))
    else
        printf 'FAIL: expected %s\n' "$assignment" >&2
        fail=$((fail + 1))
    fi
}

require_enabled CONFIG_SPL_FIT
require_enabled CONFIG_SPL_LOAD_FIT
require_enabled CONFIG_SPL_MMC
require_enabled CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_USE_SECTOR
require_enabled CONFIG_SUPPORT_EMMC_BOOT
require_value CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=0x300

printf '\nResult: %s pass, %s fail\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
