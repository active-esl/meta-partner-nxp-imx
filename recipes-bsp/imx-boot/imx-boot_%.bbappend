# Match NXP's 6.12.49-2.2.0 firmware and boot-container layout.
SRCBRANCH:imx95-frdm-evk = "lf-6.12.49_2.2.0"
SRCREV:imx95-frdm-evk = "be80fadd5e7988214149a2bc48daac1b0950d4c2"

# imx95-frdm-evk: meta-imx imx-boot copies mcore-demos → m7_image.bin for mx95 prepend.
# flash_a55 (production default) does not consume m7_image.bin in imx-mkimage.
IMX_M4_DEMOS:imx95-frdm-evk = ""
M4_DEFAULT_IMAGE_MX95:imx95-frdm-evk = "m7_image_placeholder.bin"

do_compile:prepend:imx95-frdm-evk() {
    # Satisfy meta-imx mx95 prepend cp from mcore-demos.
    install -d ${DEPLOY_DIR_IMAGE}/mcore-demos
    install -m 0644 /dev/null ${DEPLOY_DIR_IMAGE}/mcore-demos/${M4_DEFAULT_IMAGE_MX95}
}

# flash_all Makefile lists m7_image.bin as a prerequisite in ${S}/iMX95 (BOOT_STAGING).
# FRDM has no imx-m7-demos yet — empty placeholder is enough for AHAB container slot.
do_compile:prepend:lmp-mfgtool:imx95-frdm-evk() {
    install -d ${S}/iMX95
    install -m 0644 /dev/null ${S}/iMX95/m7_image.bin
}
