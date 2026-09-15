#!/bin/sh
# Keep the Jaguar/FRDM partner layer from reintroducing known BitBake errors.

set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
uboot_tools="$repo/recipes-bsp/u-boot/u-boot-imx-tools_2025.04.bb"
apparmor_append="$repo/recipes-security/apparmor/apparmor_%.bbappend"

# OE-Core owns native U-Boot host tools. Extending the NXP target recipe into
# native creates two scheduled providers for the same sysroot capabilities.
grep -Fqx 'BBCLASSEXTEND = ""' "$uboot_tools"
if grep -Eq '^PROVIDES.*class-(native|nativesdk)' "$uboot_tools"; then
    echo "NXP U-Boot tools reintroduce a competing native/SDK provider" >&2
    exit 1
fi

# Use the recipe-specific meta-clang form. The weaker toolchain-only override
# loses to clang.bbclass and leaves GCC's -flto-partition=none in AppArmor.
grep -Fqx 'LTO:pn-apparmor:toolchain-clang = ""' "$apparmor_append"
if grep -Fqx 'LTO:toolchain-clang = ""' "$apparmor_append"; then
    echo "AppArmor uses the ineffective non-recipe-specific LTO override" >&2
    exit 1
fi
