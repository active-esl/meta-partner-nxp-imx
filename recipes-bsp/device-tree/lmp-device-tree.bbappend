FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Foundries mfgtool FIT generation consumes virtual/dtb independently of the
# kernel FIT. Keep this reference-board DT in the reusable partner BSP.
SRC_URI:append:imx95-frdm-evk = " file://imx95-15x15-frdm.dts"

COMPATIBLE_MACHINE:imx95-frdm-evk = ".*"
