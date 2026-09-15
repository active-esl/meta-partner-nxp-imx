# NXP's IWxxx OTBR requires mDNSResponder's mdns package.  The package also
# installs libnss_mdns.so.2, so it fulfils the standard zeroconf dependency
# that would otherwise pull in the conflicting libnss-mdns implementation.
RPROVIDES:${PN}:append:imx95-frdm-evk = " libnss-mdns"
RREPLACES:${PN}:append:imx95-frdm-evk = " libnss-mdns"
RCONFLICTS:${PN}:append:imx95-frdm-evk = " libnss-mdns"
