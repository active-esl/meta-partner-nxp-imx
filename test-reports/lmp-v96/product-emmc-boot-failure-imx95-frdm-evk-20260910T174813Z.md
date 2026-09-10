# FRDM-IMX95 production eMMC boot failure

- Result: **FAIL — production SPL looked for the separate Foundries U-Boot FIT
  in the eMMC user area instead of the active boot hardware partition**
- Product artifact partner revision: `92d14aa8c6fc9924b0a4b5adee9c4f00b4ce6089`
- Programming result: UUU exit 0, 36/36 commands, both boot sets written
- Hardware symptom: no production UART bytes and no DHCP lease after two cold
  eMMC boots with SW1 at `(1,0)`

## Read-only media proof

The board was returned to serial-download mode and RAM-booted with the matched
recovery container. U-Boot commands read the eMMC without modifying it:

- `EXT_CSD[179]`: boot partition enabled = 1 (boot0), access = user
- boot0 sector 0: i.MX95 AHAB v2 container header (`02 23 20 87`)
- boot0 sector `0x300`: FIT header (`d0 0d fe ed`)
- boot1 sector 0 and sector `0x300`: the same valid headers
- user-area sector `0x300`: all zeroes
- user-area LBA 1: valid GPT header
- partition 1 starts at `0x2000` and contains a valid FAT16 boot filesystem

The successful probe transcript is
`logs/uuu-inspect-boot-layout-r4-20260910T174813Z.log`, SHA-256
`9a9b52dd96517f6127d92fe60d9949e4155ef236a00ae233e403cb3d311929e3`.
The authoritative command output is retained in the independent local serial
trace at `/home/ajlennon/.local/state/hwlab/serial/frdm-imx95.log`.

## Configuration and source proof

The compiled product U-Boot configuration contains:

```text
CONFIG_SPL_LOAD_FIT=y
CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=0x300
# CONFIG_SUPPORT_EMMC_BOOT is not set
```

In NXP U-Boot 2025.04, `spl_mmc_boot_mode()` returns `MMCSD_MODE_RAW` when
`CONFIG_SUPPORT_EMMC_BOOT` is disabled. When enabled it returns
`MMCSD_MODE_EMMCBOOT`, selects the partition from eMMC `part_config`, then falls
through to the same raw sector read. The disabled production build therefore
read the proven-empty user-area sector `0x300`, while mfgtools correctly wrote
the Foundries `bootloader2` FIT to sector `0x300` in boot0 and boot1.

## Corrective gate

The partner layer must enable `CONFIG_SUPPORT_EMMC_BOOT`, retain raw FIT sector
`0x300`, and increment `LMP_BOOT_FIRMWARE_VERSION`. The rebuilt production
`.config` must pass `test-plan/verify-imx95-production-uboot-config.sh` before
new boot artifacts are programmed.
