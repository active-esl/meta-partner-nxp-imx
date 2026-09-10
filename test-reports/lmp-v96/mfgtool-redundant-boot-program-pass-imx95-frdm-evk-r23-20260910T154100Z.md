# FRDM-iMX95 mfgtool redundant-boot record (r23, superseded/unsafe)

> Superseded on 2026-09-10. Hardware evidence proved that overlaying
> `u-boot.itb` at block `0x300` in either eMMC boot hardware partition can
> corrupt the AHAB container. This is a negative learning record, not a valid
> programming recipe.

Date: 2026-09-10

Partner-layer revision: `8afd6bcfc8272f13cf11ae93c3ecac8236553912`

## Problem and target-2901 comparison

The r22 recovery U-Boot exposed `bootloader` as only `0x60000` bytes and
`bootloader2` as `0x3a0000` bytes.  Foundries' primary i.MX95
`flash_a55` container is 2,592,768 bytes, so `FB: flash bootloader` failed
after the WIC write with `image too large for partition`.

The forward-ported 2025.04 U-Boot also accepted
`CONFIG_FSL_FASTBOOT_BOOTLOADER_SECONDARY=y` as an unknown fragment setting:
neither `bootloader_s` nor `bootloader2_s` existed in the compiled partition
table.  The old target-2901 lab flow had booted because its customized script
bypassed the missing named FIT slot with a direct `mmc write`; it did not prove
that the generated Foundries script was correct.

The r23 fix keeps `bootloader` at the complete 4 MiB eMMC boot-hardware-area
span and lets `bootloader2` overlap it from block `0x300`.  This models the
actual Foundries operation: install the complete NXP i.MX container, then
replace its embedded FIT with the separately Factory-signed FIT.  The same
layout is exposed in eMMC boot1 as `bootloader_s` and `bootloader2_s`.
`FSL_FASTBOOT_BOOTLOADER2_OVERLAP` is opt-in and enabled only by the
FRDM-iMX95 fragment, so existing i.MX6/i.MX8/i.MX93 layouts are unchanged.

## Clean ai-tools build

Clean layer clone:

`/srv/yocto/frdm-imx95-product-v96/meta-partner-nxp-imx-r23`

Build log:

`/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-redundant-boot-r23.log`

Result: all 2,458 tasks succeeded; 2,413 were reused.

Build-log SHA-256:

`829842fc847a205e9b6dca25afdf80c0323fe5fcfc5337dd570e13bbcf2786e0`

Compiled U-Boot configuration contains:

```text
CONFIG_FSL_FASTBOOT_BOOTLOADER2=y
CONFIG_FSL_FASTBOOT_BOOTLOADER2_OVERLAP=y
CONFIG_FSL_FASTBOOT_BOOTLOADER_SECONDARY=y
CONFIG_FSL_FASTBOOT_BOOTLOADER2_OFFSET=0x300
```

The production-r8 plus mfgtool-r23 combined verifier passed 50 checks with
zero failures.  Its log is:

`/srv/yocto/frdm-imx95-product-v96/imx95-v96-combined-artifact-verify-r23.log`

Verifier-log SHA-256:

`34933654380a5d67a58082eafbe95be4b1f91000b278852d6217838864cfb6fe`

Mfgtool archive SHA-256:

`93a46dca318fdca241eab90612d549073bbc51d25853aeae646da3d6adfa9457`

## Live non-writing partition probe

The r23 recovery U-Boot was loaded into RAM and initialized with the same
target selection used by `full_image.uuu` (`fastboot_dev=mmc`, `emmc_dev=0`,
`mmcdev=0`, `mmc dev 0 0`).  Live fastboot getvars returned:

| Target | Size | Type | Hardware area |
|---|---:|---|---|
| `all` | `0x747c00000` | `device` | eMMC user area |
| `bootloader` | `0x400000` | `raw` | eMMC boot0 |
| `bootloader2` | `0x3a0000` | `raw` | eMMC boot0, from block `0x300` |
| `bootloader_s` | `0x400000` | `raw` | eMMC boot1 |
| `bootloader2_s` | `0x3a0000` | `raw` | eMMC boot1, from block `0x300` |

Probe log:

`/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r23-redundant-boot/logs/uuu-partition-probe-r23-20260910T153700Z.log`

Probe-log SHA-256:

`b64134bd2a8144aeda47f18f5947d175e6b5a79c0dca497a48476882488416e6`

## Programming result

Bundle:

`/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r23-redundant-boot`

All entries in `PROGRAMMING-SHA256SUMS` passed before use.  The hardware run
started from the already-loaded r23 RAM fastboot state, then executed the
generated `full_image.uuu` FB stages.  It sparse-programmed the complete
Foundries WIC and installed the production container plus FIT in both boot0 and
boot1.  UUU returned exit code 0.  Optional WIC read-back verification was not
run.

Programming log:

`/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r23-redundant-boot/logs/uuu-program-r23-20260910T154000Z.log`

Programming-log SHA-256:

`909d4ce31fef8a4bcc7b2b9347d81c3fbb6d87c7a3208f29ac4d49880654fc4b`

## Remaining gates

- Select normal eMMC boot and cold-cycle the board.
- Reopen/restart the serial capture after the ACM re-enumeration, then retain a
  clean boot log proving ROM through Linux userspace.
- Run one later cold serial-download `./program-imx95.sh program` session from
  the MX95 BootROM identity to certify the complete generated operator flow;
  this r23 run certifies the RAM-fastboot and persistent-write portion.
- Keep optional read-back as a separate operator action.
