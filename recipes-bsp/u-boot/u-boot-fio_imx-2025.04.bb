# NXP's i.MX95 U-Boot baseline with the Foundries verified-boot delta
# forward-ported from 2024.04. Restrict this recipe to the i.MX95 NXP BSP so
# established i.MX6/i.MX8/i.MX93 machines keep their existing bootloader.

require recipes-bsp/u-boot/u-boot-fio-common.inc

UUU_BOOTLOADER = "uuu_bootloader_tag"
UUU_BOOTLOADER:mx8-generic-bsp = ""
UUU_BOOTLOADER:mx9-generic-bsp = ""
inherit_defer ${UUU_BOOTLOADER}

UBOOT_REPO = "git://github.com/nxp-imx/uboot-imx.git"
SRCBRANCH = "lf_v2025.04"
SRCREV = "4ddbad60eff308a5b356fb9ab8734ac382ddd692"

LIC_FILES_CHKSUM = "file://Licenses/gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"
DEPENDS += "python3-setuptools-native xxd-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-fio-2025.04:"
SRC_URI += " \
    file://0001-FIO-toup-drivers-rpmb-replicate-linux-mmc-configurat.patch \
    file://0002-FIO-toup-drivers-rpmb-use-cache-aligned-buffers-on-r.patch \
    file://0003-FIO-internal-common-fiovb-foundries.io-verified-boot.patch \
    file://0004-FIO-internal-mach-imx-spl-allow-RAM-load-instead-of-.patch \
    file://0005-FIO-internal-fastboot-establish-BOOTLOADER2-raw-part.patch \
    file://0006-FIO-extras-fit-verify-abort-if-signature-not-found-a.patch \
    file://0007-FIO-extras-cmd-bootm-allow-fit-with-imx_hab.patch \
    file://0008-FIO-extras-autoboot-imx-only-boot-from-usb-if-fastbo.patch \
    file://0009-FIO-internal-imx_env-set-mfg-to-run-fastboot-by-defa.patch \
    file://0010-FIO-toup-arch-mach-imx-fiohab-support-tool-to-enable.patch \
    file://0011-FIO-extras-fastboot-don-t-enable-console-mux-by-defa.patch \
    file://0012-FIO-fromlist-spl-Add-CONFIG_SPL_FIT_SIGNATURE_STRICT.patch \
    file://0013-FIO-toup-boot-introduce-FIT_SIGNATURE_STRICT.patch \
    file://0014-FIO-extra-image-fit-dont-use-weak-hash-if-SIGNATURE_.patch \
    file://0015-FIO-extra-boot-dont-enable-MD5-SHA1-if-SIGNATURE_STR.patch \
    file://0016-FIO-internal-imx-secondary_boot-initial-implementati.patch \
    file://0017-imx9-add-Foundries-boot-state-helpers-for-SCMI-firmw.patch \
"

DEFAULT_PREFERENCE = "-1"
COMPATIBLE_MACHINE = "(mx95-nxp-bsp)"
