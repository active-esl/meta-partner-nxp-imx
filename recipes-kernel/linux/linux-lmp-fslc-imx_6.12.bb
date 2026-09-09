# NXP's first supported FRDM-IMX95 kernel baseline. Keep it scoped to the
# i.MX95 NXP BSP override so existing i.MX6/i.MX8/i.MX93 machines continue to
# select the Foundries Linux 6.6 recipe.

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

include recipes-kernel/linux/linux-lmp-fslc-imx.inc
include recipes-kernel/linux/kmeta-linux-lmp-6.6.y.inc

LINUX_VERSION = "6.12.49"
KERNEL_REPO = "git://github.com/nxp-imx/linux-imx.git"
KERNEL_REPO_PROTOCOL = "https"
KERNEL_BRANCH = "lf-6.12.y"
SRCREV_machine = "df24f9428e38740256a410b983003a478e72a7c0"

# Retain the Foundries runtime behaviour that is still absent from NXP's
# lf-6.12.y tree. The remaining 6.6 patches are already upstream or i.MX8-only.
SRC_URI += " \
    file://0001-FIO-toimx-of-enable-using-OF_DYNAMIC-without-OF_UNIT-6.12.patch \
    file://0004-FIO-toup-hwrng-optee-support-generic-crypto-6.12.patch \
    file://0005-ALSA-compress-import-DMA_BUF-namespace.patch \
"

# The Foundries 6.6 kernel metadata is retained initially for LmP policy and
# signing integration.  Board hardware configuration comes from NXP's native
# FRDM DTS and the machine fragment; this is validated by the parse/build gate.
DEFAULT_PREFERENCE = "-1"
COMPATIBLE_MACHINE = "(mx95-nxp-bsp)"
