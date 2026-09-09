FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

PROVIDES += "virtual/trusted-firmware-a"
RPROVIDES:${PN} += "virtual-trusted-firmware-a"

SRC_URI:append = " \
    file://0001-plat-imx8m-obtain-boot-set-from-bootrom-even-log.patch \
"

deploy_opteed_atf() {
    # Newer NXP TF-A releases no longer create build-optee. The matching
    # SoC-specific deploy hook below handles that layout.
    if [ ! -f ${S}/build-optee/${ATF_PLATFORM}/release/bl31.bin ]; then
        return
    fi
    install -m 0644 ${S}/build-optee/${ATF_PLATFORM}/release/bl31.bin ${DEPLOYDIR}/arm-trusted-firmware.bin
    install -m 0644 ${S}/build-optee/${ATF_PLATFORM}/release/bl31/bl31.elf ${DEPLOYDIR}/arm-trusted-firmware.elf
}
do_deploy:append:mx8-nxp-bsp() {
    deploy_opteed_atf
}
do_deploy:append:mx9-nxp-bsp() {
    deploy_opteed_atf
}

# TF-A 2.12 builds the OP-TEE-aware i.MX95 binary in the normal build tree,
# unlike the 2.10-era recipe's separate build-optee directory.
deploy_opteed_atf_mx95() {
    install -m 0644 ${S}/build/${ATF_PLATFORM}/release/bl31.bin \
        ${DEPLOYDIR}/arm-trusted-firmware.bin
    install -m 0644 ${S}/build/${ATF_PLATFORM}/release/bl31/bl31.elf \
        ${DEPLOYDIR}/arm-trusted-firmware.elf
}
do_deploy:append:mx95-nxp-bsp() {
    deploy_opteed_atf_mx95
}
