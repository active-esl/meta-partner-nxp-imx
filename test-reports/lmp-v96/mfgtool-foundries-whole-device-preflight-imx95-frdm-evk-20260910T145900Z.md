# FRDM-IMX95 Foundries whole-device fastboot preflight

Date: 2026-09-10 14:59 BST  
Board USB serial: `D38D0250C88A43CB`  
RAM bootloader: r20 (`U-Boot 2025.04`, NXP FSL fastboot)  
USB identity: `1fc9:0152`

## Context

The first r20 full-image attempt used UUU's generic `FB: write` command. It
segfaulted in host UUU after transferring a 64 MiB chunk and did not provide a
valid Foundries WIC programming result. The replacement must retain the
Foundries mfgtool convention: convert the WIC stream to sparse chunks and flash
the complete eMMC user area as the `all` target.

## Source evidence

NXP's `CONFIG_FSL_FASTBOOT` implementation creates `all` natively in
`drivers/fastboot/fb_fsl/fb_fsl_partitions.c`. It sets start block zero, length
to the target block device's complete `lba` count, hardware partition to the
eMMC user partition, and type to `device`.

The generic `CONFIG_FASTBOOT_MMC_USER_SUPPORT` mechanism is mutually exclusive
with `CONFIG_FSL_FASTBOOT`; it is neither required nor appropriate here.

## Read-only hardware result

The following UUU fastboot queries were executed against the live r20 RAM
bootloader before any further eMMC write:

```text
FB: getvar partition-size:all
0x747c00000
Okay (0.006s)

FB: getvar partition-type:all
device
Okay (0.006s)
```

`0x747c00000` is the full 29.12 GiB eMMC user area reported by this board.

Probe log SHA-256:
`cb3fb591c80677cab405c93b07316e8553a4195076f1580c2362634d48bb5cb0`

## BSP decision

The generated `full_image.uuu` now performs both queries as a fail-fast,
pre-write compatibility gate and then uses:

```text
FB[-t 1800000]: flash -raw2sparse all ../<factory-image>.wic.gz/*
```

Full programming and post-program boot verification remain required; this
report proves only the whole-device target and the safety preflight.
