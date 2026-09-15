# AppArmor's build filters the generic -flto option but leaves OE's
# GCC-specific -flto-partition=none behind.  Clang rejects that orphaned flag,
# so keep LTO disabled for this recipe when the selected toolchain is Clang.
LTO:toolchain-clang = ""
