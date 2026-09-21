FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI:append:imx95-frdm-evk = " \
    file://0001-renderer-gl-add-full-repaint-workaround.patch \
"
