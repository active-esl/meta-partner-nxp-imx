# Foundries OSTree deliberately excludes /opt. Keep the NXP validation tools
# in the immutable /usr deployment so they remain available after an OTA.
do_install:append:imx95-frdm-evk() {
    install -d ${D}${libexecdir}
    mv ${D}/opt/g2d_samples ${D}${libexecdir}/g2d-samples
    rmdir ${D}/opt 2>/dev/null || true
}

FILES:${PN}:remove:imx95-frdm-evk = "/opt"
FILES:${PN}:append:imx95-frdm-evk = " ${libexecdir}/g2d-samples"
