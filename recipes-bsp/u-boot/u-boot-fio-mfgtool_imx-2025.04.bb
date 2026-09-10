SUMMARY = "Produces an FRDM-IMX95 Manufacturing Tool compatible U-Boot"
DESCRIPTION = "Foundries mfgtool U-Boot on the coherent NXP 2025.04 baseline"

require recipes-bsp/u-boot/u-boot-fio_imx-2025.04.bb

# Environment config is not required for mfgtool.
SRC_URI:remove = "file://fw_env.config"

DEFAULT_PREFERENCE = "-1"
COMPATIBLE_MACHINE = "(mx95-nxp-bsp)"
