# FRDM-IMX95 matched product/mfgtools build and programming gate

- Result: **PASS — exact-revision product and recovery builds, artifact gate,
  bundle assembly, and full eMMC programming**
- Product integration revision:
  `cc0c083d35b3e01b74c7ae5f84a36aeed1d2f9a7`
- Partner-layer revision:
  `92d14aa8c6fc9924b0a4b5adee9c4f00b4ce6089`
- Dynamic Devices BSP revision:
  `ad8f3a4533de4b3c6362142b308ca12a7eaa84fc`
- Dynamic Devices distro revision:
  `9d693eec2d3e841f094ce6547f3ada17d2360868`
- Hardware boot/runtime verification: **OPEN** — this report ends after the
  successful write; eMMC boot and peripheral evidence are separate gates

## Product build

The final revision-matched `lmp-factory-image` build completed 8409/8409 tasks.
The product verifier completed 38/38 checks, including Weston/KMS, Waydroid,
IW612/Thread/Zigbee, mDNS provider selection, `mlanutl`, Foundries image
artifacts, and first-boot filesystem-resize support.

- Build log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-dd-display-waydroid-r4.log`
- Build-log SHA-256:
  `72f4eb0935c9875c1397164516cc9eb5b6a1c366d56b3fef4e89f654e7935ee9`
- Product-verifier log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-dd-product-artifact-verify-r4.log`
- Product-verifier SHA-256:
  `97421f3b76db3e711cdcaf57d92027c8b58d13ee1f137eec4eca8a827260e158`
- WIC gzip SHA-256:
  `a8603aa3cc2f8eea6b03430210a655829ac116cd90e250fb660886d461fc9b11`
- Production `imx-boot` SHA-256:
  `b2ef85c35c9a14ce7de4831ff84a7ae902e555ccba89964be4acab96008335f4`
- Production U-Boot FIT SHA-256:
  `4139553fd8c914e99a26163a46d5199df0eb838324444cde8da24c3c7b264c2b`
- Manifest SHA-256:
  `e51f5527bbf57ded3ecda2420d56215489f6d00532f19c054356c379e4224b0c`

The FRDM product override adds 1 GiB of construction headroom. It does not
replace Foundries' dynamic WIC layout: `resize-helper.service` remains present
and expands the filesystem to the available storage on first boot.

## Recovery build and negative learning

The final mfgtools build completed 2458/2458 tasks after parsing 3681 recipes
with six intentionally masked partner appends and no parse errors.

- Build log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-current-92d14aa-r27.log`
- Build-log SHA-256:
  `7331e9ac69fded047cc664a163ae6519a1d36738ad656441f7a9ab08cdeb2d34`
- Mfgtools archive SHA-256:
  `37ed1d761ce1cd7b60d441352aa97b11451e3d02d8908e3de038fc3f4c1dfcc2`

Two failed attempts established the required recovery/product boundary:

1. r25 masked partner OTBR compatibility appends but left NXP's OTBR layer
   enabled. Its layer configuration injected OTBR into every image, so the
   recovery image compiled an irrelevant daemon and failed in
   `mdns_mdnssd.cpp` on `kDNSServiceErr_StaleData`.
2. r26 disabled the OTBR and Zigbee RCP layers but removed the corresponding
   masks. BitBake correctly rejected the now-dangling partner `.bbappend`
   files during parsing.

The retained solution disables both product-only connectivity layers in the
mfgtools KAS graph and narrowly masks only their partner appends. The product
graph continues to carry the connectivity packages and compatibility fixes.

## Matched-artifact and programming evidence

The combined exact-product/exact-recovery verifier passed 54/54 checks.

- Combined-verifier log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-dd-product-mfgtool-combined-r4-r27.log`
- Combined-verifier SHA-256:
  `b5a21f3808d530df37e35bc5ebf80a4307835d964cfd51dde273827f5ce001f1`
- Local bundle:
  `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-dd-product-r4-mfg-r27`
- UUU version: `libuuu_1.5.201-0-g727fc2b`
- BootROM identity: MX95 SDPS `1fc9:015d`, serial
  `D38D0250C88A43CB`
- Programming result: 36/36 fastboot commands, `Success 1`, `Failure 0`, UUU
  exit code 0
- UUU transcript:
  `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-dd-product-r4-mfg-r27/logs/uuu-program-imx95-frdm-evk-20260910T171440Z.log`
- Transcript SHA-256:
  `c0cb5d5d1aa3efe71eb1e50d06b6d58023db13416ebb32f9c0c5e3a04c09ca5b`

Programming ran through the bundled UUU directly under the logged-in operator
account. The host's UUU udev rules already grant access, so invoking UUU with
`sudo` is an avoidable failure mode and is no longer part of the maintained
operator path. The optional WIC read-back CRC was deliberately not run.

## Next gate

Power off, set SW1 to eMMC boot `(1,0)`, power on, and preserve the complete
serial log. Prove first-boot filesystem expansion, production U-Boot/FIT and
Linux boot, then run the requirement-by-requirement hardware validation plan.
