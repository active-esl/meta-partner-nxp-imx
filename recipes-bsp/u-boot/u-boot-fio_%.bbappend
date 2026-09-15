FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

require u-boot-fio-bsp-nxp-imx-common.inc

require ${THISDIR}/u-boot-fio/imx95-frdm-evk.inc

FILESEXTRAPATHS:prepend:imx95-frdm-evk := "${THISDIR}/u-boot-fio/imx95-frdm-evk:"

# The legacy 2024.04 path needs the local FRDM DTS and SCMI fixes. NXP's
# 2025.04 tree contains the native board support, so only the common Foundries
# configuration fragments are applied there.
FRDM_IMX95_UBOOT_LEGACY_URI = "${@'file://0002-skip-srctree-clean-check-out-of-tree.patch file://0003-arm-dts-add-imx95-15x15-frdm-dtb.patch file://0004-imx9-scmi-export-check-secondary-cnt-set.patch file://0005-fdt-pack-reg-unaligned-access.patch file://0006-imx9-scmi-boot-mode-for-secondary-cmd.patch file://imx95-15x15-frdm.dts;subdir=git/arch/arm/dts file://imx95-15x15-frdm-u-boot.dtsi;subdir=git/arch/arm/dts' if '2024.04' in (d.getVar('PV') or '') else ''}"
FRDM_IMX95_UBOOT_NATIVE_DISPLAY_URI = "${@'file://0007-imx95-frdm-enable-hdmi-splash-pipeline.patch' if '2025.04' in (d.getVar('PV') or '') else ''}"

SRC_URI:append:imx95-frdm-evk = " \
    file://custom-dtb.cfg \
    file://imx95-spl-scmi.cfg \
    file://fix-environment-config.cfg \
    file://lmp-spl-fit.cfg \
    file://ostree-boot.cfg \
    file://bootdelay-lab.cfg \
    file://factory-fastboot.cfg \
    file://enable-foundries-imx-commands.cfg \
    ${FRDM_IMX95_UBOOT_LEGACY_URI} \
    ${FRDM_IMX95_UBOOT_NATIVE_DISPLAY_URI} \
"

# NXP U-Boot currently races its CONFIG_DEFAULT_DEVICE_TREE existence check
# against parallel DTB builds for this target.
PARALLEL_MAKE:imx95-frdm-evk = "-j 1"
