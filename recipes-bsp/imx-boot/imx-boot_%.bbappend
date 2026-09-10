# Match NXP's 6.12.49-2.2.0 firmware and boot-container layout.
SRCBRANCH:imx95-frdm-evk = "lf-6.12.49_2.2.0"
SRCREV:imx95-frdm-evk = "be80fadd5e7988214149a2bc48daac1b0950d4c2"

# Keep meta-imx's supported mx95 path intact: imx-boot depends on
# imx-m7-demos:do_deploy and copies M4_DEFAULT_IMAGE_MX95 to m7_image.bin.
# The mfgtool flash_all container must carry that real M7 payload; a zero-byte
# stand-in can build but does not prove a valid AHAB M7 container entry.
