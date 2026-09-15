#!/bin/sh
# Keep the Jaguar/FRDM partner layer from reintroducing known BitBake errors.

set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
uboot_tools="$repo/recipes-bsp/u-boot/u-boot-imx-tools_2025.04.bb"
apparmor_append="$repo/recipes-security/apparmor/apparmor_%.bbappend"
apparmor_patch="$repo/recipes-security/apparmor/files/0001-apparmor-drop-gcc-only-lto-partition-flags.patch"

# OE-Core owns native U-Boot host tools. Extending the NXP target recipe into
# native creates two scheduled providers for the same sysroot capabilities.
grep -Fqx 'BBCLASSEXTEND = ""' "$uboot_tools"
if grep -Eq '^PROVIDES.*class-(native|nativesdk)' "$uboot_tools"; then
    echo "NXP U-Boot tools reintroduce a competing native/SDK provider" >&2
    exit 1
fi

# AppArmor 3.1.3 hard-codes the GCC-only partition option in libapparmor and
# parser build flags. Both are outside Yocto's CFLAGS, so the Clang override
# must carry a source patch that removes every source occurrence.
grep -Fqx 'FILESEXTRAPATHS:prepend := "${THISDIR}/files:"' "$apparmor_append"
grep -Fqx 'SRC_URI:append:toolchain-clang = " file://0001-apparmor-drop-gcc-only-lto-partition-flags.patch"' "$apparmor_append"
grep -Fqx 'LTO:toolchain-clang = ""' "$apparmor_append"
grep -Fqx -- '-AM_CFLAGS = -Wall $(EXTRA_WARNINGS) -fPIC -flto-partition=none' "$apparmor_patch"
grep -Fqx -- '+AM_CFLAGS = -Wall $(EXTRA_WARNINGS) -fPIC' "$apparmor_patch"
grep -Fqx -- '-CFLAGS	+= -flto-partition=none' "$apparmor_patch"
grep -Fqx -- '+CFLAGS	+=' "$apparmor_patch"
