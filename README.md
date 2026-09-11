# Foundries.io NXP i.MX partner layer

This branch carries the Foundries Linux microPlatform integration for NXP i.MX
SoCs. It extends the vendor BSP layers with the boot, update, signing and
manufacturing-tool behaviour required by LmP.

This repository is an Active ESL fork of the Foundries
[`meta-partner` `nxp-imx` branch][foundries-nxp-imx]. It preserves and builds
on that branch's existing NXP support; the FRDM-IMX95 work is an additional,
machine-scoped port rather than a replacement layer.

## Inherited Foundries NXP board support

The upstream `nxp-imx` branch already carries Foundries boot/update and
manufacturing integration for these NXP reference boards and variants:

| Reference board | Existing machine/variant names |
|---|---|
| i.MX 6UltraLite EVK | `imx6ulevk` |
| i.MX 6ULL EVK | `imx6ullevk`, `imx6ullevk-sec` |
| i.MX 8QuadMax MEK | `imx8qm-mek`, `imx8qm-mek-sec` |
| i.MX 8M Quad EVK | `imx8mq-evk`, `imx8mq-evk-ebbr` |
| i.MX 8M Mini LPDDR4 EVK | `imx8mm-lpddr4-evk`, `imx8mm-lpddr4-evk-sec`, `imx8mm-lpddr4-evk-ebbr` |
| i.MX 8M Nano DDR4/LPDDR4 EVKs | `imx8mn-ddr4-evk`, `imx8mn-lpddr4-evk` and their `-sec` variants |
| i.MX 8M Plus LPDDR4 EVK | `imx8mp-lpddr4-evk`, `imx8mp-lpddr4-evk-sec`, `imx8mp-lpddr4-evk-ebbr` |
| i.MX 93 11x11 LPDDR4X EVK | `imx93-11x11-lpddr4x-evk` |

The secure and EBBR names are configuration variants of the same physical
reference boards, not additional boards. Foundries' checked-in end-to-end
operator plans currently cover the i.MX 8M Mini, Nano DDR4, Plus and Quad
EVKs. Their other machine and mfgtools definitions are inherited here but
must not be represented as newly validated by Active ESL.

Active ESL adds `imx95-frdm-evk`, including the coherent NXP 6.12 component
set and the Foundries OSTree/FIT/WIC/mfgtools integration described below.

## Layer boundary

This layer owns reusable NXP platform integration and NXP reference-machine
support. Product images, application policy and customer-board hardware deltas
belong in the consuming Factory layers.

For FRDM-IMX95 this means:

- this layer owns the coherent NXP `lf-6.12.49-2.2.0` component set, the
  `imx95-frdm-evk` reference machine, Foundries OSTree/FIT boot integration,
  kernel and mfgtool device trees, IW612 driver/firmware alignment, WIC layout
  and UUU/mfgtools support;
- the consuming manifest enables the pinned `meta-imx-sdk` and `meta-imx-ml`
  sublayers from that same NXP revision; the FRDM runtime package group selects
  NEO libcamera, Neutron and EdgeLock from those vendor layers;
- a product distro layer selects display, Waydroid and other image features;
- Thread/Matter products pin NXP `meta-nxp-connectivity` to the same BSP
  release and select its IWxxx OTBR packages; the partner machine exposes the
  physical `has-iwxxx` capability and LPSPI3 transport;
- a customer BSP layer may inherit the generic `mx95-nxp-bsp` support and add
  only the custom board delta.

The i.MX95 support is machine-scoped. Existing i.MX6, i.MX8 and i.MX93 targets
remain on their established kernel and boot-firmware versions.

## Factory manifest integration

LmP v96 and later no longer include `meta-freescale` by default. A consuming
manifest must pin and add:

- `meta-freescale` and any required NXP vendor layers;
- `meta-imx-bsp`, `meta-imx-sdk` and `meta-imx-ml` from one pinned `meta-imx`
  revision—mixing their quarterly releases is unsupported;
- this repository on the `nxp-imx` branch or a reviewed pinned derivative;
- this layer to the Factory BSP layer list.

Do not track an unpinned branch in a production Factory manifest.

NXP's `rel_imx_6.12.49_2.2.0` connectivity tag is based on newer Yocto release
series and does not declare Scarthgap compatibility. Foundries LmP v96 is
Scarthgap, so Thread support requires a separately tested compatibility port;
do not suppress `LAYERSERIES_COMPAT` or pretend generic Linux IEEE 802.15.4
support replaces the NXP Spinel-over-SPI userspace path.

The pinned IW612 OTBR source also references
`kDNSServiceErr_StaleData`, which is not part of Scarthgap's mDNSResponder
2200 public API. The partner layer removes those unreachable switch cases and
keeps every error value exposed by the linked library. This delta is part of
the exact connectivity-release gate and must be re-audited when either OTBR or
mDNSResponder is updated.

## FRDM-IMX95 proof order

1. Parse the exact Factory manifest and audit effective providers/versions.
2. Run `kas/lmp-v96-imx95-frdm-evk-6.12-partner-acceleration.yml`, then build
   `linux-lmp-fslc-imx`, `kernel-module-nxp-wlan`,
   `firmware-nxp-wifi`, `linux-imx-headers`, `u-boot-fio`, `imx-atf`, System
   Manager, OEI, OP-TEE, `imx-boot`, `imx-g2d-samples`, `libcamera`,
   `neutron`, `tensorflow-lite-neutron-delegate`, `imx-secure-enclave` and
   `mfgtool-files` independently.
3. Build the complete Factory image and inspect its FIT, WIC and UUU bundle.
4. Program only with the i.MX95 UUU flow and retain serial evidence.
5. Prove boot, OTA/rollback and board interfaces on hardware.

The optional verification UUU script is included in the mfgtools bundle but is
not part of the default programming path.

The production FRDM package group contains only the NXP camera, Neutron and
EdgeLock runtimes. `packagegroup-partner-nxp-imx95-validation` is selected only
when `DEV_MODE = "1"`; G2D samples, media tools and crypto tests must not enter
a release image accidentally.

## Reproducible development checks

The `kas/lmp-v96-*-partner.yml` configurations pin the exact Foundries LmP v96
core and NXP layer revisions used for the compatibility baseline. They disable
production signing only inside the local test harness; the layer itself retains
the normal Foundries signing policy.

Both normal and mfgtool configurations must parse cleanly. Before integration,
the v96 baseline was also used to compile Linux 6.12.49, U-Boot 2025.04, TF-A
2.12, OP-TEE 4.8, OEI, System Manager, imx-boot, and the mfgtool variants. Keep
these component gates ahead of a complete Factory image build so failures are
attributed to the smallest responsible layer.

[foundries-nxp-imx]: https://github.com/foundriesio/meta-partner/tree/nxp-imx
