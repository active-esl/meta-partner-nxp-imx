# The wheel installer records its host-side file:// source in direct_url.json.
# This optional PEP 610 provenance file is not used at runtime and makes the
# target package non-reproducible, so omit it instead of suppressing QA.
do_install:append:imx95-frdm-evk() {
    rm -f ${D}${PYTHON_SITEPACKAGES_DIR}/tflite_runtime-${PV}.dist-info/direct_url.json
}
