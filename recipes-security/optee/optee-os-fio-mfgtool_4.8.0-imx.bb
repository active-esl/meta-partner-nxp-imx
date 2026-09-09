FILESEXTRAPATHS:prepend := "${THISDIR}/optee-os-fio:"

require optee-os-fio_${PV}.bb

RPROVIDES:${PN} += "optee-os"

DEFAULT_PREFERENCE = "-1"
