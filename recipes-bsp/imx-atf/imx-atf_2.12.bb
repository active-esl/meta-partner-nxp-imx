# Copyright (C) 2017-2025 NXP

DESCRIPTION = "i.MX ARM Trusted Firmware"
SECTION = "BSP"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/BSD-3-Clause;md5=550794465ba0ec5312d6919e203a55f9"

PV .= "+git${SRCPV}"

SRC_URI = "${ATF_SRC};branch=${SRCBRANCH}"
ATF_SRC ?= "git://github.com/nxp-imx/imx-atf.git;protocol=https"
SRCBRANCH = "lf_v2.12"
SRCREV = "a266ff458c2526a6474036a5c6648be6fdc54fe3"

S = "${WORKDIR}/git"

inherit deploy

PACKAGECONFIG ??= " \
    ${@bb.utils.filter('UBOOT_CONFIG', 'crrm', d)} \
    ${@bb.utils.filter('MACHINE_FEATURES', 'optee', d)}"

PACKAGECONFIG[crrm] = "IMX_CRRM=1"
PACKAGECONFIG[debug] = "DEBUG=1,DEBUG=0"
PACKAGECONFIG[optee] = "SPD=opteed"

ATF_PLATFORM ??= "INVALID"
ATF_BOOT_UART_BASE ?= ""

CFLAGS[unexport] = "1"
LDFLAGS[unexport] = "1"
AS[unexport] = "1"
LD[unexport] = "1"

INHIBIT_DEFAULT_DEPS = "1"
# Scarthgap predates the virtual/cross-cc provider used by Walnascar.
DEPENDS = "virtual/${HOST_PREFIX}gcc"
DEPENDS:append:toolchain-clang = " clang-cross-${TARGET_ARCH}"

def remove_options_tail (in_string):
    from itertools import takewhile
    return ' '.join(takewhile(lambda x: not x.startswith('-'), in_string.split(' ')))

EXTRA_OEMAKE = " \
    CROSS_COMPILE=${TARGET_PREFIX} \
    PLAT=${ATF_PLATFORM} \
    CC="${@remove_options_tail(d.getVar('CC'))}" \
    LD="${HOST_PREFIX}ld.bfd" \
    IMX_BOOT_UART_BASE=${ATF_BOOT_UART_BASE} \
    ${PACKAGECONFIG_CONFARGS} \
    bl31"

do_configure[noexec] = "1"
do_install[noexec] = "1"

ANNOTATED_NAME        = "bl31-${ATF_PLATFORM}.bin"
ANNOTATED_NAME:append = "${@bb.utils.contains('PACKAGECONFIG',  'crrm',  '-crrm', '', d)}"
ANNOTATED_NAME:append = "${@bb.utils.contains('PACKAGECONFIG', 'optee', '-optee', '', d)}"

addtask deploy after do_compile
do_deploy() {
    OUTPUT_FOLDER="${@bb.utils.contains('PACKAGECONFIG', 'debug', 'debug', 'release', d)}"
    for deploydir in ${DEPLOYDIR} ${DEPLOYDIR}/imx-boot-tools; do
        install -Dm 0644 ${S}/build/${ATF_PLATFORM}/${OUTPUT_FOLDER}/bl31.bin $deploydir/${ANNOTATED_NAME}
    done
    ln -sf ${ANNOTATED_NAME} ${DEPLOYDIR}/bl31.bin
}

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(mx95-generic-bsp)"
