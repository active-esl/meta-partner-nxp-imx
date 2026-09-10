# Foundries.io NXP i.MX partner layer

This branch carries the Foundries Linux microPlatform integration for NXP i.MX
SoCs. It extends the vendor BSP layers with the boot, update, signing and
manufacturing-tool behaviour required by LmP.

## Layer boundary

This layer owns reusable NXP platform integration and NXP reference-machine
support. Product images, application policy and customer-board hardware deltas
belong in the consuming Factory layers.

For FRDM-IMX95 this means:

- this layer owns the coherent NXP `lf-6.12.49-2.2.0` component set, the
  `imx95-frdm-evk` reference machine, Foundries OSTree/FIT boot integration,
  kernel and mfgtool device trees, IW612 driver/firmware alignment, WIC layout
  and UUU/mfgtools support;
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
- this repository on the `nxp-imx` branch or a reviewed pinned derivative;
- this layer to the Factory BSP layer list.

Do not track an unpinned branch in a production Factory manifest.

NXP's `rel_imx_6.12.49_2.2.0` connectivity tag is based on newer Yocto release
series and does not declare Scarthgap compatibility. Foundries LmP v96 is
Scarthgap, so Thread support requires a separately tested compatibility port;
do not suppress `LAYERSERIES_COMPAT` or pretend generic Linux IEEE 802.15.4
support replaces the NXP Spinel-over-SPI userspace path.

## FRDM-IMX95 proof order

1. Parse the exact Factory manifest and audit effective providers/versions.
2. Build `linux-lmp-fslc-imx`, `kernel-module-nxp-wlan`,
   `firmware-nxp-wifi`, `linux-imx-headers`, `u-boot-fio`, `imx-atf`, System
   Manager, OEI, OP-TEE, `imx-boot` and `mfgtool-files` independently.
3. Build the complete Factory image and inspect its FIT, WIC and UUU bundle.
4. Program only with the i.MX95 UUU flow and retain serial evidence.
5. Prove boot, OTA/rollback and board interfaces on hardware.

The optional verification UUU script is included in the mfgtools bundle but is
not part of the default programming path.

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
