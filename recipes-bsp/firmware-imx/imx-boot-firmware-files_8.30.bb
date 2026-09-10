# Copyright (C) 2018-2025 NXP
SUMMARY = "Freescale i.MX Firmware files used for boot"

require firmware-imx-${PV}.inc

inherit deploy nopackages

do_install[noexec] = "1"

DEPLOY_FOR                  = ""
DEPLOY_FOR:mx8-generic-bsp  = "mx8"
DEPLOY_FOR:mx8m-generic-bsp = "mx8m"
DEPLOY_FOR:mx9-generic-bsp  = "mx9"

deploy_for_mx8() {
    install -m 0644 ${S}/firmware/hdmi/cadence/hdmitxfw.bin ${DEPLOYDIR}
    install -m 0644 ${S}/firmware/hdmi/cadence/hdmirxfw.bin ${DEPLOYDIR}
    install -m 0644 ${S}/firmware/hdmi/cadence/dpfw.bin ${DEPLOYDIR}
}

deploy_for_mx8m() {
    for ddr_firmware in ${DDR_FIRMWARE_NAME}; do
        install -m 0644 ${S}/firmware/ddr/synopsys/${ddr_firmware} ${DEPLOYDIR}
    done
    install -m 0644 ${S}/firmware/hdmi/cadence/signed_dp_imx8m.bin ${DEPLOYDIR}
    install -m 0644 ${S}/firmware/hdmi/cadence/signed_hdmi_imx8m.bin ${DEPLOYDIR}
}

deploy_for_mx9() {
    for ddr_firmware in ${DDR_FIRMWARE_NAME}; do
        install -m 0644 ${S}/firmware/ddr/synopsys/${ddr_firmware} ${DEPLOYDIR}
    done
}

python () {
    deploy_for = d.getVar('DEPLOY_FOR', True).split()
    for soc in deploy_for:
        d.appendVarFlag('do_deploy', 'vardeps', ' deploy_for_%s' % soc)
}

do_deploy () {
    for soc in ${DEPLOY_FOR}; do
        bbnote "Running deploy for $soc"
        deploy_for_$soc
    done
}

addtask deploy after do_install before do_build

PACKAGE_ARCH = "${MACHINE_SOCARCH}"
COMPATIBLE_MACHINE = "(mx8-generic-bsp|mx9-generic-bsp)"
COMPATIBLE_MACHINE:mx8x-generic-bsp = "(^$)"
