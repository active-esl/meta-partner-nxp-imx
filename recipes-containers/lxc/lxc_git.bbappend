# clang ThinLTO cannot use the default ld.bfd linker selected by this build.
# Waydroid needs LXC, so disable Meson's LTO switch for this dependency.
EXTRA_OEMESON:append:imx95-frdm-evk = " -Db_lto=false"
