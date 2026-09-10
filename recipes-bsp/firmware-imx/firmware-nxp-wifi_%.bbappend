# Keep IW612 firmware on the same NXP LF6.12.49_2.2.0 release train as the
# FRDM kernel and out-of-tree WLAN module.  This also carries the secure
# uartspi_n61x_v1.bin.se image requested by btnxpuart on the reference board.
# The source and install layout are machine-scoped; the effective values are
# part of the task signature while the firmware recipe remains allarch.
LIC_FILES_CHKSUM:imx95-frdm-evk = "file://LICENSE.txt;md5=bc649096ad3928ec06a8713b8d787eac"
SRC_URI:imx95-frdm-evk = "git://github.com/nxp-imx/imx-firmware.git;protocol=https;branch=${SRCBRANCH}"
SRCBRANCH:imx95-frdm-evk = "lf-6.12.49_2.2.0"
SRCREV:imx95-frdm-evk = "8c9b278016c97527b285f2fcbe53c2d428eb171d"

# The 6.12 firmware repository installs directly from its top level; the
# older v96 recipe contains layout-specific copy loops for the 6.6 tree.
do_install:imx95-frdm-evk() {
    install -d ${D}${nonarch_base_libdir}/firmware/nxp
    oe_runmake install INSTALLDIR=${D}${nonarch_base_libdir}/firmware/nxp
}
