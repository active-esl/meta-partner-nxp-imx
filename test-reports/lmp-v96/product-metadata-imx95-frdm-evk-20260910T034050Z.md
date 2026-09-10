# FRDM-IMX95 product metadata gate

- Gate time: `2026-09-10T03:40:50Z`
- Machine: `imx95-frdm-evk`
- Image: `lmp-factory-image`
- Configuration: resolved product smoke KAS configuration
- BitBake environment: `/srv/yocto/frdm-imx95-product-v96-build/lmp-factory-image.env`
- Environment SHA-256: `2dcd2862b996a64ee9725bf23142f98084ea87c3a4de0f7a06b5df746eadfcbb`
- Parse result: completed with 10 warnings and no errors

## Source tuple

| Layer | Commit |
|---|---|
| `meta-dynamicdevices` | `b217e3997275da31015eb2e68d886bd263c0ad9d` (content-equivalent staging commit for product integration `b90f0a0`) |
| `meta-dynamicdevices-bsp` | `003a440994ca6d95b2bdb746923508c2a1ddc2d3` |
| `meta-dynamicdevices-distro` | `f191e4d7f078de100f850787eadbe4133316c2cc` |
| `meta-partner-nxp-imx` | `52cc3b8ed60841015c436f60b0bb91daf03de8a5` |

## Effective configuration

The generated `bitbake -e lmp-factory-image` output proves:

- `DD_PRODUCT_FEATURES="display android-container"`;
- `DISTRO_FEATURES` contains `display-runtime`, `waydroid`, `wayland`,
  `opengl`, `vulkan`, `pulseaudio` and `alsa`;
- `PREFERRED_PROVIDER_virtual/kernel="linux-lmp-fslc-imx"` and
  `PREFERRED_PROVIDER_virtual/bootloader="u-boot-fio"`;
- `KERNEL_DEVICETREE` contains the base FRDM DTB plus the NXP camera, audio,
  LVDS and Waveshare variants;
- `MACHINE_FEATURES` contains `nxpiw612-sdio`, `has-iwxxx`, `zigbee` and
  `display-multimedia`;
- `IMAGE_INSTALL` contains Weston/Wayland,
  `packagegroup-dd-android-container`, IW612 firmware and utilities,
  `zigbee-rcp-apps`, `zigbee-rcp-sdk`, `packagegroup-nxp-otbr`, the NXP
  GStreamer plugin, OP-TEE and the Foundries OSTree/update packages.

The Android package group has `RDEPENDS:${PN} = "waydroid"`. The Waydroid
recipe explicitly accepts `imx95-frdm-evk`, requires the effective graphics
features above, and enables the FRDM container/session/UI services. The
consumer BSP appends the machine-scoped Binder fragment with Binder IPC,
BinderFS, Android Binder devices and ashmem enabled.

The screen-specific Weston rootfs hook is scoped only to
`imx8mm-jaguar-screen`; it is defined during parsing but is not appended to the
FRDM image task. FRDM therefore retains normal DRM/Weston connector discovery
for the initial HDMI test.

## Evidence state

This closes the **metadata** state for HDMI/Weston, Waydroid and the NXP
connectivity package selection. It does not claim **built**, **booted** or
**hardware proven**. Those states remain gated on the full product build and
physical-board tests.
