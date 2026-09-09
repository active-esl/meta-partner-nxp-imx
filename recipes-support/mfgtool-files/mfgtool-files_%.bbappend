FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

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
