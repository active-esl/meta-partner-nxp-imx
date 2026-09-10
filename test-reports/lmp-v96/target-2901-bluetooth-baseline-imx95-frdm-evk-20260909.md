# FRDM-IMX95 target 2901 Bluetooth baseline

- Board: physical `imx95-frdm-evk`
- Running image: `Linux-microPlatform Dynamic Devices 5.0.11-2901-95.2`
- Serial capture: `/home/ajlennon/.local/state/hwlab/serial/frdm-imx95.log`
- Capture SHA-256: `a776a71fb84dd02f775db7319b62fa8c6b15a0eab855d82d2adb08cb0224f921`

## Result

Target 2901 remains evidence for a complete boot into Foundries userspace, but
it is a **negative** IW612 Bluetooth baseline. The retained capture records:

```text
[    7.049779] Bluetooth: hci0: Firmware file nxp/uartspi_n61x_v1.bin.se not found
[    9.019693] Bluetooth: hci0: Frame reassembly failed (-84)
[   71.838475] Bluetooth: hci0: Opcode 0x0c03 failed: -110
[  103.870478] Bluetooth: hci0: Setting baudrate failed (-110)
[  105.886466] Bluetooth: hci0: Setting wake-up method failed (-110)
[  107.902492] Bluetooth: hci0: Setting Power Save mode failed (-110)
```

The coherent NXP `lf-6.12.49-2.2.0` firmware recipe emits
`firmware-nxp-wifi-nxpiw612-sdio_1.1-r0_all.ipk` with SHA-256
`e8859d168143600904d2e8a493e9c94e572e9578daed18c4b8125a6025e03371`.
Its payload contains the requested 429,436-byte
`/usr/lib/firmware/nxp/uartspi_n61x_v1.bin.se` and the 330,460-byte
`uartuart_n61x_v1.bin.se` companion image.

This proves that the replacement BSP builds and packages the missing firmware;
it does not yet prove that the product rootfs installs it or that the radio
works. After programming the integrated v96 image, require the file on target,
zero `btnxpuart` firmware/protocol errors, a powered `hci0`, discovery of a
known advertiser, pairing and a data/audio exchange before promoting Bluetooth
to hardware proven.
