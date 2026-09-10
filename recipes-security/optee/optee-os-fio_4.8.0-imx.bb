FILESEXTRAPATHS:prepend := "${THISDIR}/optee-os-fio:"

require recipes-security/optee/optee-os-fio.inc

# meta-imx packagegroup-fsl-optee-imx depends on this compatibility name.
RPROVIDES:${PN} += "optee-os"

# NXP 6.12.49-2.2.0 baseline with the reviewed Foundries 4.4 delta
# forward-ported as a layer patch.
require optee-os-fio-4.8.0-imx-source.inc

DEFAULT_PREFERENCE = "-1"
