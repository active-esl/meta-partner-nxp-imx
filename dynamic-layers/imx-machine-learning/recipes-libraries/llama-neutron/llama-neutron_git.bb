SUMMARY = "llama.cpp Neutron NPU experiment tools for FRDM-IMX95"
DESCRIPTION = "Pinned experimental Q4_0 matrix-multiply backend, offline weight packer, benchmark and correctness test. No models or services are installed."
HOMEPAGE = "https://github.com/open-ep/llama-neutron"
LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=223b26b3c1143120c87e2b13111d3e99 \
    file://ggml/src/ggml-cpu/neutron/NOTICE;md5=95c27f33a3164fd0bc805c385115136f \
"

SRC_URI = "git://github.com/open-ep/llama-neutron.git;protocol=https;branch=neutron-npu"
SRC_URI += "file://neutron-api-check.cpp"
SRC_URI += " \
    file://0001-neutron-release-tracked-bootstrap-mapping.patch \
    file://mapping-tail-guard.h \
"
SRCREV = "a74a3f86a8708517a139b548f91793d615dc4b0c"
PV = "0.0+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake features_check

REQUIRED_DISTRO_FEATURES += "llama-neutron"

COMPATIBLE_MACHINE = "^imx95-frdm-evk$"
DEPENDS = "neutron"

EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_NATIVE=OFF \
    -DGGML_CPU_NEUTRON=ON \
    -DGGML_CPU_KLEIDIAI=OFF \
    -DGGML_OPENMP=OFF \
    -DGGML_BACKEND_DL=OFF \
    -DLLAMA_BUILD_COMMON=ON \
    -DLLAMA_BUILD_TOOLS=ON \
    -DLLAMA_BUILD_TESTS=ON \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_APP=OFF \
    -DLLAMA_OPENSSL=OFF \
    -DLLAMA_LLGUIDANCE=OFF \
"

# The older FRDM vendor stack has the graph API but not the low-level matmul
# API this fork requires. Fail clearly before compiling the complete backend;
# do not silently upgrade vendor firmware or substitute a CPU-only build.
do_configure:prepend() {
    # Keep the reviewed ownership parser beside the patched backend. This
    # runtime-specific workaround affects only this FRDM experiment recipe.
    install -m 0644 ${WORKDIR}/mapping-tail-guard.h ${S}/ggml/src/ggml-cpu/neutron/
    install -d ${B}
    ${CXX} ${CPPFLAGS} ${CXXFLAGS} ${LDFLAGS} \
        -I${S}/ggml/src/ggml-cpu/neutron ${WORKDIR}/neutron-api-check.cpp \
        -lNeutronDriver -o ${B}/neutron-api-check || \
        bbfatal "llama-neutron requires the Neutron matrix and weight-packing APIs. The selected neutron provider is incompatible; no automatic BSP/firmware upgrade is performed."
}

# Build only the experiment executables and their dependency libraries, not
# every upstream tool/test. Never execute target tests on the build host.
do_compile() {
    cmake --build ${B} -- ${PARALLEL_MAKE} llama-completion llama-bench neutron-pack test-neutron-mm
}

do_install() {
    install -d ${D}${bindir} ${D}${libdir} ${D}${datadir}/llama-neutron
    for tool in llama-completion llama-bench neutron-pack test-neutron-mm; do
        install -m 0755 ${B}/bin/$tool ${D}${bindir}/$tool
    done
    # Preserve the SONAME symlink chains of the libraries built by the targets.
    cp -P ${B}/bin/lib*.so* ${D}${libdir}/
    install -m 0644 ${S}/docs/backend/NEUTRON.md ${D}${datadir}/llama-neutron/
    install -m 0644 ${S}/ggml/src/ggml-cpu/neutron/NOTICE ${D}${datadir}/llama-neutron/
}

# These libraries belong only to this experimental fork; do not advertise it
# as a replacement provider for another llama.cpp/ggml installation.
PRIVATE_LIBS = "libllama.so.0 libggml.so.0 libggml-base.so.0 libggml-cpu.so.0"
PRIVATE_LIBS += "libllama-common.so.0"
PRIVATE_LIBS += "libllama-completion-impl.so libllama-bench-impl.so"
# Upstream's CLI implementation libraries are unversioned runtime ELF files,
# not development linker symlinks. Keep the normal dev split for the five
# versioned libraries while assigning these two tool dependencies to runtime.
FILES_SOLIBSDEV = " \
    ${libdir}/libllama.so \
    ${libdir}/libllama-common.so \
    ${libdir}/libggml.so \
    ${libdir}/libggml-base.so \
    ${libdir}/libggml-cpu.so \
"
FILES:${PN} += "${libdir}/libllama-completion-impl.so ${libdir}/libllama-bench-impl.so"
RDEPENDS:${PN} += "neutron"

PACKAGES =+ "${PN}-tests"
FILES:${PN}-tests = "${bindir}/test-neutron-mm"
RDEPENDS:${PN}-tests = "${PN}"
