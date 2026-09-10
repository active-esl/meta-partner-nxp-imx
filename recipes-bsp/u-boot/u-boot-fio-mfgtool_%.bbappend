FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

require u-boot-fio-bsp-nxp-imx-common.inc

require ${THISDIR}/u-boot-fio/imx95-frdm-evk.inc

FILESEXTRAPATHS:prepend:imx95-frdm-evk := "${THISDIR}/u-boot-fio/imx95-frdm-evk:"

FRDM_IMX95_UBOOT_MFGTOOL_LEGACY_URI = "${@'file://0001-kconfig-imx95-secondary-boot-sector-offset.patch file://0002-skip-srctree-clean-check-out-of-tree.patch file://0003-arm-dts-add-imx95-15x15-frdm-dtb.patch file://0004-imx9-scmi-export-check-secondary-cnt-set.patch file://imx95-15x15-frdm.dts;subdir=git/arch/arm/dts file://imx95-15x15-frdm-u-boot.dtsi;subdir=git/arch/arm/dts' if '2024.04' in (d.getVar('PV') or '') else ''}"

SRC_URI:append:imx95-frdm-evk = " \
    file://custom-dtb.cfg \
    file://mfgtool-fastboot.cfg \
    file://fix-environment-config.cfg \
    ${FRDM_IMX95_UBOOT_MFGTOOL_LEGACY_URI} \
"

PARALLEL_MAKE:imx95-frdm-evk = "-j 1"

# disable branch protection to fix SPL size overrun issue
TOOLCHAIN_OPTIONS:append:mx8mp-nxp-bsp = ' -mbranch-protection=none'
