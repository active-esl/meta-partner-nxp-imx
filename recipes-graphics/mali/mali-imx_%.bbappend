# The NXP Weston stack opens the GBM loader by its unversioned name at runtime.
# Upstream Mali recipes assign that link to the development package, leaving
# production images with only libgbm.so.1. Apply this packaging fix across the
# Mali recipe version selected by the pinned BSP.
FILES:${PN}-libgbm:append:imx95-frdm-evk = " ${libdir}/libgbm${SOLIBSDEV}"
FILES:${PN}-libgbm-dev:remove:imx95-frdm-evk = "${libdir}/libgbm${SOLIBSDEV}"

# This link is a runtime ABI requirement for NXP's Weston integration, so the
# usual dev-so packaging rule does not apply to this board-specific package.
INSANE_SKIP:${PN}-libgbm:append:imx95-frdm-evk = " dev-so"
