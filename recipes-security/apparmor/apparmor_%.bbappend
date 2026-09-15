# AppArmor's build filters the generic -flto option but can leave OE's
# GCC-specific -flto-partition=none behind. Clang rejects that orphaned flag.
# This bbappend is already recipe-specific, so disable LTO for its Clang build
# and remove the unsupported sub-option from every compiler/linker flag path.
LTO:toolchain-clang = ""
CFLAGS:remove:toolchain-clang = "-flto-partition=none"
CXXFLAGS:remove:toolchain-clang = "-flto-partition=none"
LDFLAGS:remove:toolchain-clang = "-flto-partition=none"
