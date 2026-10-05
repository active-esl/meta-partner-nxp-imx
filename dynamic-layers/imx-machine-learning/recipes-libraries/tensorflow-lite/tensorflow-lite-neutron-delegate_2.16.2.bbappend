FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# NXP adds its source tree to the linker search path even though both Neutron
# libraries are supplied by the recipe sysroot. CMake consequently emits the
# source tree as a RUNPATH in libneutron_delegate.so, failing buildpaths QA.
SRC_URI:append:imx95-frdm-evk = "${@oe.utils.conditional('FRDM_NEUTRON_EXPERIMENT', '1', ' file://0002-build-delegate-partition-helper.patch', ' file://0001-drop-source-directory-runpath.patch', d)}"

# The 3.1 runtime no longer supplies NeutronConverter and uses unsigned
# custom-operation sizes. Keep its matching delegate source with the existing
# product TensorFlow Lite ABI; do not repin its provider or affect normal images.
# The newer CMake layout has no source-directory RUNPATH to remove.
python __anonymous() {
    if d.getVar("MACHINE") == "imx95-frdm-evk" and d.getVar("FRDM_NEUTRON_EXPERIMENT") == "1":
        d.setVar("SRCBRANCH_neutron", "lf-6.18.20_2.0.0")
        d.setVar("SRCREV_neutron", "4a38248c74b83b0b7f4f2a9091e095e1e92247d0")
        # The product's meta-tensorflow provider is 2.16.1, not the NXP
        # 2.16.2 CMake provider. Match its exact source and installed SONAME.
        d.setVar("TENSORFLOW_LITE_SRC", "git://github.com/tensorflow/tensorflow.git;protocol=https")
        d.setVar("SRCBRANCH_tf", "r2.16")
        d.setVar("SRCREV_tf", "5bc9d26649cca274750ad3625bd93422617eed4b")
        d.appendVar("EXTRA_OECMAKE", " -DTFLITE_LIB_LOC=${STAGING_DIR_HOST}${libdir}/libtensorflowlite.so")
        d.setVar("OECMAKE_TARGET_COMPILE", "neutron_delegate")
}

# Never let vendor CMake silently build a second TensorFlow runtime when the
# expected product library is absent. This gate observes the recipe sysroot.
do_configure:prepend:imx95-frdm-evk() {
    if [ "${FRDM_NEUTRON_EXPERIMENT}" = "1" ]; then
        test -f ${RECIPE_SYSROOT}${libdir}/libtensorflowlite.so || \
            bbfatal "FRDM experiment requires the existing product libtensorflowlite.so"
    fi
}

# The recipe's second TensorFlow source tree lives outside S and B, so it is
# not covered by Yocto's default DEBUG_PREFIX_MAP. Cover all recipe sources.
CXXFLAGS:append:imx95-frdm-evk = " \
    -ffile-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
    -fdebug-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
    -fmacro-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV} \
"
