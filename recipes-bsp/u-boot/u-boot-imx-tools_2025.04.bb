require recipes-bsp/u-boot/u-boot-tools.inc
require u-boot-imx-common_${PV}.inc

DEPENDS += "python3-setuptools-native"

PROVIDES:append:class-target = " ${MLPREFIX}u-boot-tools"
PROVIDES:append:class-native = " u-boot-tools-native"
PROVIDES:append:class-nativesdk = " nativesdk-u-boot-tools"

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE:class-target = "(imx-generic-bsp)"

# Do not alter the established i.MX6/i.MX8/i.MX93 provider selection.
DEFAULT_PREFERENCE = "-1"
