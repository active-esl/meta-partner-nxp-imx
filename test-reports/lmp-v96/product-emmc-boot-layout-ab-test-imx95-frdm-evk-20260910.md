# FRDM-IMX95 eMMC boot-layout A/B result

Date: 2026-09-10  
Board UID: `d38d0250c88a43cb858274f2f2d067ed`

## Result

The NXP/Foundries-compatible i.MX95 split layout is demonstrated on hardware:

- complete `imx-boot` AHAB container at block zero of eMMC boot0;
- optional intact recovery copy of the same container in boot1;
- separate `u-boot.itb` in the eMMC user area at LBA `0x300`;
- `CONFIG_SUPPORT_EMMC_BOOT` disabled, so SPL reads the raw FIT from user area.

Writing the FIT at boot0/boot1 LBA `0x300`, or enabling
`CONFIG_SUPPORT_EMMC_BOOT`, is not this board's layout.

## Evidence

The known-good target-2901 Foundries script writes `imx-boot` to boot0, then
selects user hwpart zero before writing `u-boot.itb` at LBA `0x300`. Its AHAB
container has essential non-zero data at byte offset `0x60000`, proving that a
FIT overlay there is intrinsically unsafe.

The controlled diagnostic restored the earlier intact 6.12 `imx-boot` to
boot0 and boot1, wrote its FIT to user LBA `0x300`, and left GPT, VFAT, OSTree,
and rootfs unchanged. UUU exited zero. On the next cold eMMC boot UART showed:

```text
U-Boot SPL 2025.04-g4ddbad60eff3-dirty
Normal Boot
Trying to boot from MMC1
## Checking hash(es) for config config-1 ...
fit_config_verify_required_keys: No signature node found: FDT_ERR_NOTFOUND
SPL_FIT_SIGNATURE_STRICT needs a valid config node in FIT
```

This proves BootROM loaded the intact container and SPL found the user-area
FIT. The remaining stop is independent: the local unsigned build retained
strict FIT verification because unqualified `UBOOT_SIGN_ENABLE = "0"` did not
override the BSP's `:sota` secure default. Local KAS must use
`UBOOT_SIGN_ENABLE:sota = "0"`; signed production builds retain strict checks.

Diagnostic log: `uuu-diagnostic-user-area-fit-20260910T181328Z.log`, SHA-256
prefix `ed8aa8c`.
