# Weston’s NXP G2D renderer opens the GBM loader by its unversioned name at
# runtime.  The upstream Mali recipe assigns that link to the development
# package, leaving production images with only libgbm.so.1.
FILES:${PN}-libgbm:append:imx95-frdm-evk = " ${libdir}/libgbm${SOLIBSDEV}"
FILES:${PN}-libgbm-dev:remove:imx95-frdm-evk = "${libdir}/libgbm${SOLIBSDEV}"
