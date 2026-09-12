# NXP's pinned recipe passes CFLAGS through EXTRA_OECONF with only its i.MX
# include path.  That discards Yocto's optimisation and debug-prefix maps and
# leaks TMPDIR into every plugin's debug symbols.  Match the corrected
# meta-freescale form for FRDM without altering other machines.
EXTRA_OECONF:imx95-frdm-evk = ""
CFLAGS:append:imx95-frdm-evk = " ${INCLUDE_DIR}"
