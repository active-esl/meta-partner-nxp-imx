FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# NXP's pinned IW612 OTBR source refers to an Apple-only/newer
# DNSServiceErrorType value which is absent from Scarthgap's mDNSResponder
# 2200 public header.  Keep this release-compatibility delta beside the NXP
# partner integration rather than modifying the product layer.
SRC_URI += "file://0001-mdns-drop-unavailable-stale-data-error.patch"
