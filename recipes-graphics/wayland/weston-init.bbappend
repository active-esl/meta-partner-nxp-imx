# imx weston-init tries to uncomment [shell] for some machines
# this is already uncommented for lmp-wayland weston.ini so remove here
INI_UNCOMMENT_ASSIGNMENTS:remove:imx-nxp-bsp = "\\[shell\\]"

# NXP's mx95 machine overrides select the DPU G2D renderer.  Keep that vendor
# default: the matching CONFIG_IMX_DPU_BLIT dependency is explicit in the
# machine kernel fragment.  Pixman remains available as a manual diagnostic
# fallback but is not the shipped renderer.
