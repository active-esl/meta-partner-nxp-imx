# Partner layer image requirements are selected through the
# lmp-partner-image.inc compatibility symlink consumed by lmp-factory-image.

# The FRDM display is handed directly to Weston. meta-lmp's Wayland feature
# adds the Foundries psplash package explicitly; remove it for this machine so
# the board does not paint a vendor splash before the product compositor.
CORE_IMAGE_BASE_INSTALL:remove:imx95-frdm-evk = "psplash"
IMAGE_FEATURES:remove:imx95-frdm-evk = "splash"

# Reference-board runtime support. The package group points at the matching
# recipes in the pinned NXP meta-imx release; the partner layer owns selection
# and Foundries integration, not private copies of vendor components.
CORE_IMAGE_BASE_INSTALL:append:imx95-frdm-evk = " \
    packagegroup-partner-nxp-imx95-runtime \
    ${@oe.utils.conditional('DEV_MODE', '1', 'packagegroup-partner-nxp-imx95-validation', '', d)} \
"
