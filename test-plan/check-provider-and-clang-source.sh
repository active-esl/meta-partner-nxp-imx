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

# AppArmor removes the generic -flto option itself, which can strand GCC's
# partition option in the effective C/C++/link flags. Clang rejects it, so the
# recipe-specific append must explicitly remove it from every relevant path.
grep -Fqx 'LTO:toolchain-clang = ""' "$apparmor_append"
for flags in CFLAGS CXXFLAGS LDFLAGS; do
    grep -Fqx "${flags}:remove:toolchain-clang = \"-flto-partition=none\"" "$apparmor_append"
done
