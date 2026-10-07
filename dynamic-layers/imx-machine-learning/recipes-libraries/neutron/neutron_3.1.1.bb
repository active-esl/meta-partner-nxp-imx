# Backport the vendor runtime only; do not adopt its Yocto layer or kernel.
# Recipe name/source pin match meta-imx 52516b92a70669eb58b805810f2a27a07c874771.
require recipes-libraries/neutron/neutron_1.0.0.bb

LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=bc649096ad3928ec06a8713b8d787eac"
SRCBRANCH = "lf-6.18.20_2.0.0"
SRCREV = "d0ff138390aeba2b6c5169d8f0ca13f6a6b8219a"

# FRDM-only, opt-in. Normal images retain the existing vendor recipe.
COMPATIBLE_MACHINE = "^imx95-frdm-evk$"
DEFAULT_PREFERENCE = "-1"

# Layer priority outranks DEFAULT_PREFERENCE. Exclude this optional software
# provider unless the distro selects it; core BSP NPU support is unchanged.
inherit features_check
REQUIRED_DISTRO_FEATURES += "llama-neutron"
