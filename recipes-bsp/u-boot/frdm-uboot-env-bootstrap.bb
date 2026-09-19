SUMMARY = "Bootstrap the FRDM persistent U-Boot environment"
DESCRIPTION = "Installs the compiled production U-Boot defaults on boards flashed before the FAT environment was initialized."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://frdm-uboot-env-bootstrap \
    file://frdm-uboot-env-bootstrap.service \
"

S = "${WORKDIR}"
COMPATIBLE_MACHINE = "(^$)"
COMPATIBLE_MACHINE:imx95-frdm-evk = "(.*)"

inherit systemd

do_install[depends] += "u-boot-fio:do_deploy"
RDEPENDS:${PN} += "u-boot-fw-utils"

do_install() {
    env_image="${DEPLOY_DIR_IMAGE}/uboot.env-${MACHINE}"
    test -s "${env_image}" || bbfatal "missing deployed FRDM U-Boot environment image"
    test "$(stat -c %s "${env_image}")" -eq 16384 || bbfatal "invalid deployed FRDM U-Boot environment image size"

    install -Dm0644 "${env_image}" \
        "${D}${nonarch_base_libdir}/firmware/frdm/uboot.env.initial"
    install -Dm0755 "${WORKDIR}/frdm-uboot-env-bootstrap" \
        "${D}${libexecdir}/frdm-uboot-env-bootstrap"
    install -Dm0644 "${WORKDIR}/frdm-uboot-env-bootstrap.service" \
        "${D}${systemd_system_unitdir}/frdm-uboot-env-bootstrap.service"
}

SYSTEMD_SERVICE:${PN} = "frdm-uboot-env-bootstrap.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += " \
    ${nonarch_base_libdir}/firmware/frdm/uboot.env.initial \
    ${libexecdir}/frdm-uboot-env-bootstrap \
"
