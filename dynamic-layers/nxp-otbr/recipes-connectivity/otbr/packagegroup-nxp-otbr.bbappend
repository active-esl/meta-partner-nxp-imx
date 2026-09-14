# NXP's package group installs both the generic UART-oriented OTBR and the
# IWxxx SPI-oriented fork when has-iwxxx is set. They own overlapping service,
# D-Bus and web-frontend paths and cannot coexist. FRDM-IMX95 uses the onboard
# IW612 SPI RCP, so retain otbr-iwxxx (and tayga) and remove generic otbr.
RDEPENDS:${PN}:remove:mx95-nxp-bsp = "otbr"
