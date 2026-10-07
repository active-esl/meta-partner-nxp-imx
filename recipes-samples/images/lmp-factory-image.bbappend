# Do not rely solely on the generic lmp-partner-image.inc compatibility name:
# a product layer can provide the same BBPATH entry and win include lookup.
# The uniquely named partner policy is therefore attached explicitly here.
require recipes-samples/images/lmp-partner-nxp-imx-image.inc

# Explicit opt-in for the FRDM development experiment. Keep model downloads,
# services and recovery/mfgtool images outside this package selection.
CORE_IMAGE_BASE_INSTALL:append:imx95-frdm-evk = " ${@bb.utils.contains('DISTRO_FEATURES', 'llama-neutron', 'packagegroup-partner-nxp-imx95-neutron-experiment', '', d)}"
