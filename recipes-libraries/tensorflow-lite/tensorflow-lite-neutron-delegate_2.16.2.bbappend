FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# NXP adds its source tree to the linker search path even though both Neutron
# libraries are supplied by the recipe sysroot. CMake consequently emits the
# source tree as a RUNPATH in libneutron_delegate.so, failing buildpaths QA.
SRC_URI:append:imx95-frdm-evk = " file://0001-drop-source-directory-runpath.patch"

# The recipe's second TensorFlow source tree lives outside S and B, so it is
# not covered by Yocto's default DEBUG_PREFIX_MAP. Cover all recipe sources.
CXXFLAGS:append:imx95-frdm-evk = " \
    -ffile-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
    -fdebug-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
    -fmacro-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
"
