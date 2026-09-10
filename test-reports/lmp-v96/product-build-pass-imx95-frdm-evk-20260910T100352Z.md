# FRDM-IMX95 v96 partner-layer product build r8

- Result: **PASS — build and static product-artifact gates**
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-partner3fbc71c-distrof73d50a-bsp97cf68c-r8.log`
- Terminal time: 2026-09-10 10:03:52 UTC
- Terminal summary: 8,423 tasks attempted, 8,287 reused, all succeeded
- Warnings: 15; expected local-development signing and OSTree persistence warnings
- Full log SHA-256: `ac1c5c5f17772034f7078d3b1134015f77f017a526610a5bdb43178420cf0c1e`
- ai-tools source heads: product `94abebf`, partner `3fbc71c`, distro
  `f73d50a`, BSP `97cf68c`
- Reviewed local equivalents: partner review `3fbc71c`, partner development
  `1a3fe7e`, distro `39af55f`, BSP `625d066`

The independent product-artifact verifier passed 34 checks with no failures.
It proves the Factory manifest, OTA, tar, WIC, bmap and testdata outputs;
production A55 boot firmware and U-Boot FIT; ATF, M33, OEI and OP-TEE
firmware; the OSTree repository/ref; and the expected display, Waydroid,
IW612, Thread/Zigbee and networking packages. Generic `otbr` is rejected in
favour of the NXP IW612 provider.

The final Factory WIC is 2,869,653,504 bytes and its gzip is 526,758,861
bytes. Artifact fingerprints are:

- WIC gzip: `f9f28b3c6972cd0d7398579ec6de320da959f6778571cbcc4750a72366d2e18f`
- production imx-boot: `0fa6438fb181dd0786bc0991b1d4dff2adbaf68d925d28045c6b2709264c5ebd`
- production U-Boot FIT: `18976b94fd7e12bf1cb747cc9c01a1b5d8e17612a29d384d7e16bcbc49272`
- product manifest: `e51f5527bbf57ded3ecda2420d56215489f6d00532f19c054356c379e4224b0c`
- OSTree ref: `43d096c14f76667ebf4fbade4179e1e98d55c228664a3180c0c1c9cee45b43bc`

The deployed `imx95-15x15-frdm.dtb` is 92,646 bytes and contains both
`eeprom@50` and the `atmel,24c256` compatible. The kernel configuration built
into this image has `CONFIG_EEPROM_AT24=m`, `CONFIG_IMX_SCMI_BBM_EXT=y` and
`CONFIG_RTC_DRV_IMX_BBM_SCMI=y`. This preserves the hardware ownership
boundary: Linux accesses the board EEPROM on LPI2C2 directly, while System
Manager owns the PCA2131 on LPI2C1 and presents its RTC through SCMI BBM.
The same configuration retains the i.MX95 DPU and Android binder/binderfs
requirements.

This report closes the current source build and static product-artifact gate.
The mfgtools recovery archive is a separate build output and is deliberately
not claimed by the 34-check product-only run. A matching recovery build,
atomic programming bundle and on-board programming/boot/peripheral evidence
remain required for hardware acceptance.
