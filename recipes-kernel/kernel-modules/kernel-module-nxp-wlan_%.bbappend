# Align IW612 with NXP's LF6.12.49_2.2.0 BSP.  Foundries v96 carries the
# lf-6.6.52_2.2.0 module, which uses cfg80211 and RPS internals that changed in
# Linux 6.12.  Scope the upgrade to FRDM-iMX95 so existing Foundries machines
# retain their validated driver revision.
SRC_URI:imx95-frdm-evk = "${MRVL_SRC};branch=${SRCBRANCH}"
SRCBRANCH:imx95-frdm-evk = "lf-6.12.49_2.2.0"
SRCREV:imx95-frdm-evk = "84ca65c9ff935d7f2999af100a82531c22c65234"

# Match the module policy shipped by NXP for this 6.12 release.
KERNEL_MODULE_PROBECONF:append:imx95-frdm-evk = " moal"
module_conf_moal:imx95-frdm-evk = "options moal mod_para=nxp/wifi_mod_para.conf"
KERNEL_MODULE_AUTOLOAD:append:imx95-frdm-evk = " moal"
