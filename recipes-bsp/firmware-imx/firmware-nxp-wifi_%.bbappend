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

# The v96 meta-imx append adds nxpiw610-sdio even though the matching
# meta-freescale recipe already declares it.  Keep the upstream package order
# but collapse duplicate names before package QA evaluates the final list.
python () {
    if d.getVar("MACHINE") == "imx95-frdm-evk":
        packages = d.getVar("PACKAGES").split()
        d.setVar("PACKAGES", " ".join(dict.fromkeys(packages)))
}

# NXP's 6.12 firmware tree adds SD filename variants, IW610 USB images and
# AW693 PCIe firmware that the older v96 package manifest does not own.
# Assign every installed file explicitly so package QA remains a hard gate.
FILES:${PN}-nxp8997-sdio:append:imx95-frdm-evk = " \
    ${nonarch_base_libdir}/firmware/nxp/sd8997* \
    ${nonarch_base_libdir}/firmware/nxp/sduart8997* \
"
FILES:${PN}-nxp9098-sdio:append:imx95-frdm-evk = " \
    ${nonarch_base_libdir}/firmware/nxp/sd9098* \
    ${nonarch_base_libdir}/firmware/nxp/sduart9098* \
"
FILES:${PN}-nxpiw610-sdio:append:imx95-frdm-evk = " \
    ${nonarch_base_libdir}/firmware/nxp/*iw610*.se \
"

PACKAGES:append:imx95-frdm-evk = " ${PN}-nxpaw693-pcie"
FILES:${PN}-nxpaw693-pcie:imx95-frdm-evk = " \
    ${nonarch_base_libdir}/firmware/nxp/*aw693* \
"
RDEPENDS:${PN}-nxpaw693-pcie:append:imx95-frdm-evk = " ${PN}-nxp-common"
