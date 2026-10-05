# Backport the vendor runtime only; do not adopt its Yocto layer or kernel.
# Recipe name/source pin match meta-imx 52516b92a70669eb58b805810f2a27a07c874771.
require recipes-libraries/neutron/neutron_1.0.0.bb

LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=bc649096ad3928ec06a8713b8d787eac"
SRCBRANCH = "lf-6.18.20_2.0.0"
SRCREV = "d0ff138390aeba2b6c5169d8f0ca13f6a6b8219a"

# FRDM-only, opt-in. Normal images retain the existing vendor recipe.
COMPATIBLE_MACHINE = "^imx95-frdm-evk$"
DEFAULT_PREFERENCE = "-1"

# Layer priority outranks DEFAULT_PREFERENCE. Exclude this provider entirely
# unless the isolated experiment explicitly enables it.
python __anonymous() {
    if d.getVar("FRDM_NEUTRON_EXPERIMENT") != "1":
        raise bb.parse.SkipRecipe("FRDM Neutron runtime requires FRDM_NEUTRON_EXPERIMENT = 1")
}
