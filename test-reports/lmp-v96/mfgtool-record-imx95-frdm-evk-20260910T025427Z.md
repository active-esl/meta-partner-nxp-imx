# FRDM-IMX95 v96 mfgtools build record

- Result: **PASS — current-head mfgtools build and production-artifact gate**
- Source tree: `233a4bb` (`nxp-imx: build OP-TEE TA devkit for mfgtools`)
- Host/workspace: `ai-tools:/srv/yocto/frdm-imx95-partner-v96`
- Mfgtools finish: 2026-09-10 02:54:27 UTC
- Mfgtools BitBake: 2,448 attempted; 2,300 reused; all succeeded; 10 warnings
- Production restore finish: 2026-09-10 02:59:11 UTC
- Production BitBake: 5,255 attempted; 5,187 reused; all succeeded; 13 warnings

The local unsigned/TUF warnings and existing static-library/build-path QA
warnings do not invalidate this artifact gate. They are not production signing
evidence.

## Logs

| Log | Bytes | SHA-256 |
|---|---:|---|
| `imx95-v96-mfgtool-current-233a4bb.log` | 62,631 | `a5da1eb25b9199ac812ec43fa2d8e1e79fe832e79cb0e08dbce63eca63ae7a39` |
| `imx95-v96-factory-after-mfgtool-233a4bb.log` | 47,483 | `c4974fb9c102083b3e63c41ef314be53adc6148cbbc19f9ad90bc9e50888e88e` |

## Programming artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `mfgtool-files-imx95-frdm-evk.tar.gz` | 37,803,890 | `83d3a1272d71450a8707c4e1944f05e34c6155e00d4e73d0d8de7d78fad01637` |
| bundled `imx-boot-mfgtool` (`flash_all`) | 2,479,104 | `dba59cadbbe673d9d46c4e4bf6fe2289ad9e55aae96a6f11fd5666210e52ba32` |
| bundled `u-boot-mfgtool.itb` | 1,519,406 | `53d6aebc1457788ad190696fbed194cab875327846a285177dab7a334009cae9` |
| bundled mfgtool FIT/initramfs | 33,261,392 | `d3e14553cb2dd51e20f693f8202456c37fc64d87f1351a71038e7b3bf853ad60` |
| mfgtool initramfs CPIO | 18,854,170 | `435ca10c1ad53ccb261e2600fbb756d873952ab57a642b0950f669bea4a34671` |
| production `imx-boot-imx95-frdm-evk` (`flash_a55`) | 2,592,768 | `9918fea05790da485fe54d714cded02f8efb4b8ca753b195ff12b8d224c98261` |
| production `u-boot-imx95-frdm-evk.itb` | 1,716,350 | `b5242076cb14715a0e06ba4adcace3a5d3fc36b68f7a5dedbd5d72e554bdee21` |
| `lmp-factory-image-imx95-frdm-evk.wic.gz` | 250,874,668 | `17318de4847e6d2342dd09c432342e85759f257e49a5d109feda19093fc2fb4f` |

The production boot container and U-Boot FIT are deliberately hash-distinct
from their recovery counterparts. The production `imx-boot-${MACHINE}` link
resolves to `imx-boot-imx95-frdm-evk-sd.bin-flash_a55`.

## i.MX95 companion-core evidence

The mfgtool `imx-boot` compile log records `flash_all`, a CM7 entry at load
address `0x303c0000`, file offset `0xab000`, and size `0x9400`. Its selected
`m7_image.bin` is 37,084 bytes with SHA-256
`fe292f489c14738844c71693a65785842ade42cf0420bf58bc99a08c02ec078d`,
byte-identical to
`imx95-15x15-evk_m7_TCM_power_mode_switch.bin`. The four other 15x15 M7
payloads required by `IMAGE_BOOT_FILES` are also non-empty (142,308; 33,468;
33,204; and 52,644 bytes).

## UUU script gate

Bundled UUU reports version 1.5.179. `uuu -dry` accepts both `full_image.uuu`
and the separate optional `verify_image.uuu` when the bundle is placed beside
the production artifacts. The normal script streams the complete compressed
Foundries WIC to eMMC user storage, then writes the production boot container
and FIT to both Foundries boot slots. Verification compares WIC and storage
from the 4 MiB boundary, intentionally excluding the boot-payload gap that is
overwritten after the WIC stream.

NXP's [UUU command definition](https://github.com/nxp-imx/mfgtools/blob/master/uuu/uuu.lst)
specifies that `seek` skips bytes on storage and `skip` skips bytes in the
input file. Using both at 4 MiB therefore compares like-for-like offsets.

## Negative evidence retained

A shared local deploy directory initially ended the mfgtools build with the
generic production names pointing at the recovery providers. The build was
green but the programming directory was unsafe. Foundries avoids this by
publishing Factory and mfgtools as separate runs. For local shared-cache work,
the mfgtools gate must run before the final production Factory gate, and the
production/recovery target names and hashes must be checked before UUU.

This record proves build and script integrity only. Hardware programming,
boot, rollback and peripheral evidence remain open.
