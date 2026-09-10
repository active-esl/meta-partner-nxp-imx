PV = "4.8.0-imx"

# The generic recipe only recognises providers named optee-os or optee-os-fio.
# lmp-mfgtool deliberately selects optee-os-fio-mfgtool, so provide the same
# build implementation before the generic recipe adds its devkit do_install.
FILESEXTRAPATHS:prepend := "${THISDIR}/optee-os-fio:"
include ${@bb.utils.contains('PREFERRED_PROVIDER_virtual/optee-os', 'optee-os-fio-mfgtool', 'recipes-security/optee/optee-os-fio.inc', '', d)}
require recipes-security/optee/optee-os-tadevkit_4.4.0.bb
include ${@bb.utils.contains('PREFERRED_PROVIDER_virtual/optee-os', 'optee-os-fio-mfgtool', 'optee-os-fio-4.8.0-imx-source.inc', '', d)}

DEFAULT_PREFERENCE = "-1"
