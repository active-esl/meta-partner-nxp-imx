# imx weston-init tries to uncomment [shell] for some machines
# this is already uncommented for lmp-wayland weston.ini so remove here
INI_UNCOMMENT_ASSIGNMENTS:remove:imx-nxp-bsp = "\\[shell\\]"

# NXP's DPU G2D renderer passes Waydroid's secondary gralloc handle FD to the
# DPU95 cache-sync ioctl, which rejects it and leaves the Android surface black.
# The Mali GL renderer imports the primary DMA-BUF correctly and keeps host
# composition accelerated.
PACKAGECONFIG:remove:imx95-frdm-evk = "use-g2d"
