require recipes-bsp/u-boot/u-boot-tools.inc
require u-boot-imx-common_${PV}.inc

DEPENDS += "python3-setuptools-native"

PROVIDES:append:class-target = " ${MLPREFIX}u-boot-tools"

# This recipe supplies the target-side tools from NXP's 2025.04 tree.  Do not
# extend it into a second native/SDK provider: OE-Core owns the host mkimage,
# mkenvimage and mkeficapsule tools used by the LmP FIT and imx-boot tasks.
# Building both providers in one task graph is an error, not a preference issue.
BBCLASSEXTEND = ""

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE:class-target = "(imx-generic-bsp)"

# Do not alter the established i.MX6/i.MX8/i.MX93 provider selection.
DEFAULT_PREFERENCE = "-1"
