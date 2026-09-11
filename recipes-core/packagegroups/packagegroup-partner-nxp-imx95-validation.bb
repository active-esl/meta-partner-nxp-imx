SUMMARY = "NXP i.MX95 development validation tools"
DESCRIPTION = "Bench tools used to prove FRDM-IMX95 hardware acceleration and interfaces"
LICENSE = "MIT"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(imx95-frdm-evk)"

RDEPENDS:${PN} = " \
    alsa-utils \
    can-utils \
    cryptodev-tests \
    imx-g2d-samples \
    libdrm-tests \
    media-ctl \
    v4l-utils \
    weston-examples \
"
