# imx-mkimage stages inputs in ${S}/${IMX_BOOT_SOC_TARGET}, which BitBake does
# not empty when a changed MACHINE_FEATURES value reruns do_compile.  Without
# this guard, an OP-TEE-enabled build followed by an OP-TEE-free recovery build
# silently reuses the old tee.bin and defeats the latter configuration.
do_compile:prepend:mx95-nxp-bsp() {
    if ! ${DEPLOY_OPTEE}; then
        rm -f ${BOOT_STAGING}/tee.bin ${BOOT_STAGING}/tee.bin-stmm
    fi
}
