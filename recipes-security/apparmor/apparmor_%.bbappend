# AppArmor 3.1.3 hard-codes GCC's -flto-partition=none in libapparmor's
# AM_CFLAGS. It is not inherited from Yocto's CFLAGS, so variable removal alone
# cannot reach it. Patch the source only for Clang and also disable recipe LTO.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:toolchain-clang = " file://0001-libapparmor-drop-gcc-only-lto-partition-flag.patch"

LTO:toolchain-clang = ""
