# AppArmor's build filters the generic -flto option but leaves OE's
# GCC-specific -flto-partition=none behind. Clang rejects that orphaned flag,
# so use the recipe-specific toolchain override form established by meta-clang
# to disable LTO for AppArmor only.
LTO:pn-apparmor:toolchain-clang = ""
