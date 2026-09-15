# FRDM-IMX95 manufacturing bundle

Place this directory beside the Foundries image artifacts, then put the board
in USB serial-download mode.

Program the board (verification is not run):

    ./mfgtool-files-imx95-frdm-evk/uuu \
        ./mfgtool-files-imx95-frdm-evk/full_image.uuu

Update only the redundant production boot firmware, retaining the existing
Foundries WIC/OSTree filesystem:

    ./mfgtool-files-imx95-frdm-evk/uuu \
        ./mfgtool-files-imx95-frdm-evk/bootloader.uuu

Optionally perform a complete read-back CRC of the WIC payload after flashing:

    ./mfgtool-files-imx95-frdm-evk/uuu \
        ./mfgtool-files-imx95-frdm-evk/verify_image.uuu

Both scripts use `imx-boot-mfgtool`, built from the i.MX95 `flash_all` target,
and decompress the neighbouring `.wic.gz` on the host. The production
`imx-boot` and `u-boot.itb` remain the Foundries build artifacts. This bundle
pins UUU 1.5.201 because older releases cannot split the i.MX95 AHAB-v2/V2X
container correctly between SDPS and SDPV.

Install the UUU udev rules on the programming host so the operator can access
the NXP BootROM and fastboot USB identities directly. Do not wrap UUU in
`sudo`: the guarded operator entry point is intended to run unprivileged and
its device checks must exercise the same permissions used for programming.

Before its first persistent write, `full_image.uuu` requires the complete
i.MX95 redundant raw-partition layout in both eMMC boot partitions and checks
that the production container and FIT fit their respective regions. These
preflight downloads are RAM-only; the separate read-back CRC remains optional.
`bootloader.uuu` applies the same slot and payload preflight but performs no
write to the eMMC user area.
