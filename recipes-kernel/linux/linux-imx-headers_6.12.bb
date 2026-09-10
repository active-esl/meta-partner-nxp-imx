# Copyright 2017-2026 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Installs i.MX-specific Linux 6.12 UAPI headers"
DESCRIPTION = "Installs the i.MX-specific userspace kernel headers from the same NXP source revision used by the FRDM-IMX95 kernel."
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRC_URI = "git://github.com/nxp-imx/linux-imx.git;protocol=https;branch=lf-6.12.y"
SRCREV = "df24f9428e38740256a410b983003a478e72a7c0"

S = "${WORKDIR}/git"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

IMX_UAPI_HEADERS = " \
    dma-buf.h \
    hantrodec.h \
    hx280enc.h \
    ipu.h \
    imx_vpu.h \
    mxc_dcic.h \
    mxc_mlb.h \
    mxc_sim_interface.h \
    mxc_v4l2.h \
    mxcfb.h \
    pxp_device.h \
    pxp_dma.h \
    version.h \
    videodev2.h \
"

do_install() {
    # Install into B first so only the exported UAPI tree is packaged.
    oe_runmake headers_install INSTALL_HDR_PATH=${B}${exec_prefix}

    # Keep parity with linux-libc-headers: the kernel should not export this.
    rm -f ${B}${exec_prefix}/include/scsi/scsi.h
    find ${B}${includedir} -name ..install.cmd -delete

    # Export only the NXP-specific ABI used by multimedia consumers.
    for h in ${IMX_UAPI_HEADERS}; do
        install -D -m 0644 ${B}${includedir}/linux/$h \
                       ${D}${includedir}/imx/linux/$h
    done
}

ALLOW_EMPTY:${PN} = "1"
INHIBIT_DEFAULT_DEPS = "1"
DEPENDS += "unifdef-native bison-native rsync-native"
PACKAGE_ARCH = "${MACHINE_SOCARCH}"

# The established i.MX machines retain meta-imx's 6.6 UAPI package. Only the
# machine-scoped NXP i.MX95 baseline may select these aligned 6.12 headers.
COMPATIBLE_MACHINE = "(mx95-nxp-bsp)"
COMPATIBLE_HOST = "(null)"
COMPATIBLE_HOST:use-nxp-bsp = ".*"
