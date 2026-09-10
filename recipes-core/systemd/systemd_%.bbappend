# meta-nxp-otbr carries a patch for older systemd which removes an explicit
# rejection of router advertisements received from the interface's own
# link-local address. systemd 255 has refactored sd-ndisc: that rejection no
# longer exists, so the desired behaviour is already present and the old patch
# cannot apply. Keep this exception scoped to the FRDM i.MX95 partner port.
SRC_URI:remove:imx95-frdm-evk = "file://0001-Patch-to-allow-creating-Address-and-Route-when-RA-is.patch"
