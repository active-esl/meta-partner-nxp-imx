# FRDM-IMX95 integrated product Zigbee failure record

- Result: **FAIL — retained compatibility evidence**
- Product: `lmp-dynamicdevices`, `DD_PRODUCT_FEATURES="display android-container"`
- Machine: `imx95-frdm-evk`
- Product source: staged `b217e3997275da31015eb2e68d886bd263c0ad9d`
- Partner source: staged `3d3464f1c4def534eb9c9718481a5cc94931b033`
- NXP connectivity source: `14a32aa7467f58257e3bb93a5c0fa443c70ae1ae`
- Start: 2026-09-10 04:51:25 UTC
- Finish: 2026-09-10 05:55:15 UTC
- BitBake: 2,719 attempted; 0 reused; one failed
- Main log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-3d3464f-r1.log`,
  1,104,950 bytes, SHA-256
  `1774d8e31c249934292dbd9ca85314c8881b187984be4e2ae089efbda8041649`
- Task log:
  `ai-tools:/srv/yocto/frdm-imx95-product-v96-build/tmp/work/cortexa55-lmp-linux/zigbee-rcp-sdk/1.0/temp/log.do_unpack.737423`,
  129 bytes, SHA-256
  `4c52b6c26adcaf66e6293510c0cbe9e82e616b695c9d48da87a61f1bb076dfb6`

## Failure

```text
ERROR: zigbee-rcp-sdk-1.0-r0 do_unpack: Directory name ${@d.getVar('S')
contains unexpanded bitbake variable.
ERROR: Task (.../zigbee-rcp-sdk.bb:do_unpack) failed with exit code '1'
```

The pinned NXP `rel_imx_6.12.49_2.2.0` recipe sets
`S = "${UNPACKDIR}"`. Its own guide describes the newer
`sources-unpack` layout, but Foundries v96 uses BitBake 2.8.1 from Scarthgap,
where `UNPACKDIR` is not defined. The vendor tarball has `bin/`, `include/`,
`libs/` and `services/` at its archive root, so Scarthgap extracts the exact
layout consumed by `do_install` directly into `WORKDIR`.

The partner fix is intentionally machine-scoped:

```bitbake
S:imx95-frdm-evk = "${WORKDIR}"
```

It is committed as `af46d90` locally and as the content-equivalent `a65da3e`
in the ai-tools staged partner checkout.

## Test-plan correction

The earlier green `packagegroup-nxp-otbr` gate did not include
`zigbee-rcp-sdk` in its dependency graph, although the complete Dynamic
Devices product installs both `zigbee-rcp-sdk` and `zigbee-rcp-apps`. That
green result was valid only for OTBR and must not be promoted to a complete
IW612 connectivity result.

`kas/lmp-v96-imx95-frdm-evk-6.12-partner-zigbee.yml` now builds
`zigbee-rcp-apps`, forcing the SDK through unpack, install, package and a real
compile consumer before another complete product build. The failed build was
allowed to drain its already-running fetch tasks; all 249 observed librsvg crate
sources are therefore cached for the retry rather than discarded.
