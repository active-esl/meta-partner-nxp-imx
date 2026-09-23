# imx weston-init tries to uncomment [shell] for some machines
# this is already uncommented for lmp-wayland weston.ini so remove here
INI_UNCOMMENT_ASSIGNMENTS:remove:imx-nxp-bsp = "\\[shell\\]"

# NXP's DPU G2D renderer passes Waydroid's secondary gralloc handle FD to the
# DPU95 cache-sync ioctl, which rejects it and leaves the Android surface black.
# The Mali GL renderer imports the primary DMA-BUF correctly and keeps host
# composition accelerated.
PACKAGECONFIG:remove:imx95-frdm-evk = "use-g2d"

# Waydroid requests an xdg-shell fullscreen surface on this appliance.  Hide
# desktop-shell's panel so the first configure is the full 1920x1080 output,
# rather than the maximized 1920x1050 work area visible on the HDMI display.
do_install:append:imx95-frdm-evk() {
    weston_ini="${D}${sysconfdir}/xdg/weston/weston.ini"
    if ! grep -qx '\[shell\]' "${weston_ini}"; then
        bbfatal "missing [shell] section in ${weston_ini}"
    fi
    if ! grep -qx 'panel-position=none' "${weston_ini}"; then
        sed -i '/^\[shell\]$/a panel-position=none' "${weston_ini}"
    fi
}
