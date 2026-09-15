SUMMARY = "Produces an FRDM-IMX95 Manufacturing Tool compatible U-Boot"
DESCRIPTION = "Foundries mfgtool U-Boot on the coherent NXP 2025.04 baseline"

require recipes-bsp/u-boot/u-boot-fio_imx-2025.04.bb

# Environment config is not required for mfgtool.
SRC_URI:remove = "file://fw_env.config"

DEFAULT_PREFERENCE = "-1"
COMPATIBLE_MACHINE = "(mx95-nxp-bsp)"

# u-boot-configure.inc invokes interactive oldconfig after merging fragments
# for a named UBOOT_CONFIG.  This NXP baseline loses stdin in that path and
# spins forever on EOF.  Resolve new symbols from defaults deterministically.
uboot_configure_config() {
    config=$1
    type=$2

    oe_runmake -C ${S} O=${B}/${config} ${config}
    if [ -n "${@' '.join(find_cfgs(d))}" ]; then
        merge_config.sh -m -O ${B}/${config} ${B}/${config}/.config ${@" ".join(find_cfgs(d))}
        oe_runmake -C ${S} O=${B}/${config} olddefconfig
    fi
}
