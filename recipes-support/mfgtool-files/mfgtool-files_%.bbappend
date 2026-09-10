FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The lf-6.12.49-2.2.0 i.MX95 flash_all image uses AHAB container header v2
# and carries the V2X header before the SPL container.  UUU 1.5.179 predates
# both parsers and sends the complete image during SDPS; SPL starts after its
# first container and disconnects the ROM endpoint while the host is still
# writing, producing LIBUSB_ERROR_IO.  Keep legacy machines on Foundries'
# existing binary, but require the first UUU release containing both fixes for
# FRDM-i.MX95 (v2 landed in 1.5.197; V2X landed in 1.5.201).
UUU_RELEASE:imx95-frdm-evk = "1.5.201"

# BitBake 2.8 does not accept override syntax on a varflag assignment. Select
# the checksums after MACHINE overrides have resolved instead.
python __anonymous () {
    if d.getVar("MACHINE") == "imx95-frdm-evk":
        d.setVarFlag("SRC_URI", "Linux.sha256sum", "61f73454b2f60c419dc8d81ce1566092d57f105ca914ef4667162cec39d984c6")
        d.setVarFlag("SRC_URI", "Mac_arm.sha256sum", "c963f40e34680373377e0820075014e2dc082751d146b87adc9779c7ec61aff8")
        d.setVarFlag("SRC_URI", "Mac_x86.sha256sum", "c81c0b1a0f616c976aa74e873715863cc1b1d0dbe5609b7413cc527f5231cef8")
        d.setVarFlag("SRC_URI", "Windows.sha256sum", "48cf245711e99fd6c118cf6b63722ba5551b7e57f334184b7c73fbea5bbf460e")
}

SRC_URI:append:imx95-frdm-evk = " \
    file://verify_image.uuu.in \
    file://README-imx95-mfgtool.md \
"

do_compile:append:imx95-frdm-evk() {
    sed -e 's/@@MACHINE@@/${MACHINE}/' \
        -e 's/@@MFGTOOL_FLASH_IMAGE@@/${MFGTOOL_FLASH_IMAGE}/' \
        -e 's/@@IMAGE_NAME_SUFFIX@@/${IMAGE_NAME_SUFFIX}/' \
        ${S}/verify_image.uuu.in > verify_image.uuu
}

SRC_URI:append:imx6ullevk-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

SRC_URI:append:imx8qm-mek-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

SRC_URI:append:imx8mm-lpddr4-evk-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

SRC_URI:append:imx8mp-lpddr4-evk-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

SRC_URI:append:imx8mn-ddr4-evk-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

SRC_URI:append:imx8mn-lpddr4-evk-sec = " \
    file://fuse.uuu \
    file://close.uuu \
    file://readme.md \
"

# Machine specific dependencies
def get_do_deploy_depends(d):
    imxboot_families = ['mx8-nxp-bsp', 'mx93-nxp-bsp', 'mx95-nxp-bsp']
    cur_families = (d.getVar('MACHINEOVERRIDES') or '').split(':')
    if any(map(lambda x: x in cur_families, imxboot_families)):
        return "imx-boot:do_deploy"
    return ""

do_deploy[depends] += "${@get_do_deploy_depends(d)}"

do_deploy:prepend:mx93-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/imx-boot ${DEPLOYDIR}/${PN}/imx-boot-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
    install -m 0644 ${DEPLOY_DIR_IMAGE}/fitImage-${INITRAMFS_IMAGE}-${MACHINE}-${MACHINE} ${DEPLOYDIR}/${PN}/fitImage-${MACHINE}-mfgtool
}

# i.MX95 mfgtools uses the flash_all boot container for the ROM-to-SPL
# transition. A production flash_a55 container is not interchangeable.
do_deploy:prepend:mx95-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 "${DEPLOY_DIR_IMAGE}/imx-boot-${MACHINE}-sd.bin-flash_all" \
        ${DEPLOYDIR}/${PN}/imx-boot-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb \
        ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
    install -m 0644 ${DEPLOY_DIR_IMAGE}/fitImage-${INITRAMFS_IMAGE}-${MACHINE}-${MACHINE} \
        ${DEPLOYDIR}/${PN}/fitImage-${MACHINE}-mfgtool
    install -m 0644 ${WORKDIR}/verify_image.uuu ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/README-imx95-mfgtool.md \
        ${DEPLOYDIR}/${PN}/README.md
}

do_deploy:prepend:mx8-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/imx-boot ${DEPLOYDIR}/${PN}/imx-boot-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
    install -m 0644 ${DEPLOY_DIR_IMAGE}/fitImage-${INITRAMFS_IMAGE}-${MACHINE}-${MACHINE} ${DEPLOYDIR}/${PN}/fitImage-${MACHINE}-mfgtool
}

do_deploy:prepend:mx6ul-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/SPL ${DEPLOYDIR}/${PN}/SPL-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
}

do_deploy:prepend:mx6ull-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/SPL ${DEPLOYDIR}/${PN}/SPL-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
}

do_compile:append:imx6ullevk-sec(){
    sed -i -e 's/SPL-mfgtool/&.signed/g' -e 's/SPL-.*-sec/&.signed/g' bootloader.uuu
    sed -i -e 's/SPL-mfgtool/&.signed/g' -e 's/SPL-.*-sec/&.signed/g' full_image.uuu
}

do_deploy:prepend:imx6ullevk-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}

do_compile:append:imx8qm-mek-sec() {
    sed -i 's/imx-boot.*/&.signed/g' bootloader.uuu
}

do_deploy:prepend:imx8qm-mek-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}

do_compile:append:imx8mm-lpddr4-evk-sec() {
    sed -i 's/imx-boot.*/&.signed/g' bootloader.uuu
}

do_deploy:prepend:imx8mm-lpddr4-evk-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}

do_compile:append:imx8mp-lpddr4-evk-sec() {
    sed -i 's/imx-boot.*/&.signed/g' bootloader.uuu
}

do_deploy:prepend:imx8mp-lpddr4-evk-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}

do_compile:append:imx8mn-ddr4-evk-sec() {
    sed -i 's/imx-boot.*/&.signed/g' bootloader.uuu
}

do_deploy:prepend:imx8mn-ddr4-evk-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}

do_compile:append:imx8mn-lpddr4-evk-sec() {
    sed -i 's/imx-boot.*/&.signed/g' bootloader.uuu
}

do_deploy:prepend:imx8mn-lpddr4-evk-sec() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${WORKDIR}/fuse.uuu ${DEPLOYDIR}/${PN}/fuse.uuu
    install -m 0644 ${WORKDIR}/close.uuu ${DEPLOYDIR}/${PN}/close.uuu
    install -m 0644 ${WORKDIR}/readme.md ${DEPLOYDIR}/${PN}/readme.md
}
