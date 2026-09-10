# FRDM-IMX95 v96 display/Waydroid product build

- Result: **PASS — build and static artifact gates**
- Build unit: `frdm-imx95-product-r7.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-partnerf37401f-distrof73d50a-bsp97cf68c-r7.log`
- Terminal time: 2026-09-10 08:49:48 UTC
- Terminal summary: 8,423 tasks attempted, 8,402 reused, all succeeded
- Full log SHA-256: `5d3f02f14667b1c7a8b7ebd2945a12e400bf2c5bc514dc27cddf77989ec826ba`
- ai-tools source heads: product `94abebf`, partner `f37401f`, distro `f73d50a`, BSP `97cf68c`
- Reviewed local equivalents: partner through `2bfbd97`, distro `39af55f`, BSP `625d066`

The independent product artifact verifier passed 29 checks with no failures.
It proves non-empty Factory manifest, OTA, tar, WIC, bmap and testdata outputs;
production A55 boot firmware; U-Boot FIT; ATF, M33, OEI and OP-TEE firmware;
the OSTree repository/ref; and selection of ELE, IW612 firmware/driver, Weston,
Waydroid, Zigbee RCP and NXP OTBR packages.

The final product package and rootfs gates also prove:

- `mlanutl` passed package QA; its AArch64 PIE contains `GNU_HASH`, `BIND_NOW`
  and `NOW PIE` dynamic flags.
- `gstreamer1.0-plugins-bad-kms` passed package QA and installs
  `/usr/lib/gstreamer-1.0/libgstkms.so`.
- `iptables` no longer owns `/etc/ethertypes`; `netbase` remains its provider.
- the evaluated NXP OTBR package group is `tayga otbr-iwxxx`; generic `otbr` is
  absent, and the rootfs contains the IW612 agent, control utility and SPI setup
  script.
- the four FRDM Waydroid provisioning/container/session/UI services and their
  helper programs are present and enabled.
- the immutable Android release marker pins system image
  `36602c0ddb9096d1ad9f0d55f95e701a1ab3faabdbbf641f1441efa932bd1fd4`,
  vendor image
  `4b68820b43b6a3f27bfd4ccb62107226d1e23bfd8f302051734aa087c112b730`,
  and source lock
  `88e0df156ccec87b89a5e1f57a5cb20d5bc1589ceb724243202ce0cb78877413`.
- Linux 6.12.49 enables binder IPC, binderfs and the binder/hwbinder/vndbinder
  plus anbox device names required by Waydroid.
- the Foundries WIC is a 2.67-GiB GPT image generated from the partner layer's
  `emmc-imx-gpt-sota-imx95.wks`; its OSTree ref is
  `6d41fab73ab230e852e2cdecad724d3702b4edd692517a449d506d50d6f498b4`.

## Programming bundle

The new production output was paired with the independently built and already
verified i.MX95 recovery archive using the atomic programming-bundle helper.
Both programming and optional verification scripts pass the bundled UUU dry
parser; recovery and production boot payloads are distinct.

- Local bundle: `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r7`
- Product WIC gzip: `dd3f63cfb4da3bd486fe3616a980931436f10e0cbc58383b0d1f80c10fe80282`
- Production imx-boot: `0fa6438fb181dd0786bc0991b1d4dff2adbaf68d925d28045c6b2709264c5ebd`
- Production U-Boot FIT: `18976b94fd770e12bf1cb747cc9c01a1b5d8e17612a29d3848d7e16bcbc49272`
- Recovery mfgtools archive: `83d3a1272d71450a8707c4e1944f05e34c6155e00d4e73d0d8de7d78fad01637`
- Post-transfer `sha256sum -c`: four of four passed

This report closes the build/static-artifact gate only. Programming, boot-log,
HDMI/Weston, Waydroid network/graphics, wired Ethernet, IW612 radios and the
remaining physical peripheral tests still require on-board evidence.
