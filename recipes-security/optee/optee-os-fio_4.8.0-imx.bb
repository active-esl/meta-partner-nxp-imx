FILESEXTRAPATHS:prepend := "${THISDIR}/optee-os-fio:"

require recipes-security/optee/optee-os-fio.inc

# meta-imx packagegroup-fsl-optee-imx depends on this compatibility name.
RPROVIDES:${PN} += "optee-os"

# NXP 6.12.49-2.2.0 baseline with the reviewed Foundries 4.4 delta
# forward-ported as a layer patch.
OPTEE_OS_REPO = "git://github.com/nxp-imx/imx-optee-os.git"
SRCBRANCH = "lf-6.12.49_2.2.0"
SRCREV = "771a7ca0494110b5eee1229cc175c755ab8c7e00"
SRC_URI:append = " file://0001-optee-retain-foundries-security-pkcs11-delta.patch"

DEFAULT_PREFERENCE = "-1"
