# NXP OP-TEE source tuple for the coherent lf-6.12.49-2.2.0 BSP.
# Shared by the runtime OS and TA devkit recipes so their ABI cannot drift.
OPTEE_OS_REPO = "git://github.com/nxp-imx/imx-optee-os.git"
SRCBRANCH = "lf-6.12.49_2.2.0"
SRCREV = "771a7ca0494110b5eee1229cc175c755ab8c7e00"
SRC_URI:append = " file://0001-optee-retain-foundries-security-pkcs11-delta.patch"
