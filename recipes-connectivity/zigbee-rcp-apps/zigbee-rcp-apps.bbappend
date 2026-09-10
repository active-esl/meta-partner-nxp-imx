# NXP's lf-6.12.49-2.2.0 recipe targets newer BitBake releases where
# UNPACKDIR is defined. LmP v96 is based on Scarthgap and fetches the
# application CMake files directly into WORKDIR.
S:imx95-frdm-evk = "${WORKDIR}"
