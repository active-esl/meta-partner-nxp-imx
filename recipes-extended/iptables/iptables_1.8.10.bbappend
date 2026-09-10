# netbase owns /etc/ethertypes in OE-Core. The pinned LmP v96 OE-Core
# revision predates upstream scarthgap fix a970b6c927fb, so nft-enabled
# iptables otherwise collides with netbase when the NXP OTBR package group
# pulls both into the FRDM-IMX95 image.
do_install:append:mx95-nxp-bsp() {
    rm -f ${D}${sysconfdir}/ethertypes
}
