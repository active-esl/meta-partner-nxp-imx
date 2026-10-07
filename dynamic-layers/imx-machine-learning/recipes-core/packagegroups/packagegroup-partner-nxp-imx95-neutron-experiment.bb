SUMMARY = "Opt-in FRDM-IMX95 Neutron LLM experiment"
DESCRIPTION = "llama.cpp Neutron backend and correctness test, without model downloads, server services or CMA changes"
LICENSE = "MIT"

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "^imx95-frdm-evk$"

inherit packagegroup features_check

REQUIRED_DISTRO_FEATURES += "llama-neutron"

RDEPENDS:${PN} = " \
    llama-neutron \
    llama-neutron-tests \
"
