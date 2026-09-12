SUMMARY = "NXP i.MX95 production acceleration runtimes"
DESCRIPTION = "Camera, Neutron NPU and EdgeLock userspace for FRDM-IMX95"
LICENSE = "MIT"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(imx95-frdm-evk)"

RDEPENDS:${PN} = " \
    imx-secure-enclave \
    libcamera \
    libcamera-gst \
    neutron \
    tensorflow-lite-neutron-delegate \
"
