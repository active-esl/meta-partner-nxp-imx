# FRDM-IMX95 v96 partner build record

- Result: **PASS — baseline full Factory image build**
- Source tree: `6442be5` (`nxp-imx: complete 6.12 Wi-Fi firmware packaging`)
- Host/workspace: `ai-tools:/srv/yocto/frdm-imx95-partner-v96`
- Start: 2026-09-10 00:42:53 UTC
- Finish: 2026-09-10 01:57:20 UTC
- BitBake: 5,255 attempted; 803 reused; all succeeded; 15 warnings
- Log: `imx95-v96-partner-full.log`, 1,822,591 bytes,
  SHA-256 `0bba4af85d004d6771d6569cc79af0e2f150c96f3a973308978543eb190993e0`

The unsigned local-development gate intentionally had no TUF packed
credentials; the two OSTree push/check credential warnings are expected and
are not production-signing evidence.

## Key deploy artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `lmp-factory-image-imx95-frdm-evk-20260910004306.wic` | 1,360,589,824 | `13e9d62362aa3057f6ae160b07227d7a70b929a806f306f58af9a4454fb3ae54` |
| `lmp-factory-image-imx95-frdm-evk-20260910004306.wic.gz` | 250,529,321 | `4a5d35f699ff05fd17492c4121970883df43136a53a88cd65afdd0eb5f6d7998` |
| `imx-boot-imx95-frdm-evk-sd.bin-flash_a55` | 2,592,768 | `cf278de9cc49b17d08dfeaf2f222d3defceb7484c42b2a32d1bb722210806938` |
| `u-boot-imx95-frdm-evk-sd-imx-2025.04.itb` | 1,716,366 | `a6455bd1c5a37486786ff73facbccfbff11cd71a66b9a38b520005cb93e42693` |
| `fitImage--6.12.49...bin` | 14,281,820 | `0498c300584b11fe9f85884c97da76b7cca82a68739cf9373d43ad46af6c0842` |
| `imx95-15x15-frdm.dtb` | 92,557 | `7afc72ee347a98ceeecaaecb4b2f420dddad67fef64020234e2660f7f27ee740` |
| Factory manifest | 97,415 | `a15233205a372d11c09f12b6f4b96487731780b1b5e731bc09dd5c16d4c157f9` |

The zero-byte `.ota` file is a local unsigned placeholder; the generated
`ota-ext4`, `ota-ext4.gz` and `ota.tar.xz` outputs are non-empty.

## Scope

This proves the coherent v96/NXP 6.12 Factory image path through rootfs,
OSTree commit, OTA ext4 and WIC. It predates the later UAPI, native U-Boot
tools, i.MX95 DPU/NETC/NPU/media and Thread compatibility fixes, so it is a
retained baseline—not the image to program for final hardware acceptance.
