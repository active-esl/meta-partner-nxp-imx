# FRDM-IMX95 v96 device-tree provider gate

- Result: **PASS for metadata/build evidence; hardware proof remains open**
- Machine: `imx95-frdm-evk`
- Linux: `6.12.49`, NXP `lf-6.12.y`
- Kernel source revision: `df24f9428e38740256a410b983003a478e72a7c0`
- Base source: `arch/arm64/boot/dts/freescale/imx95-15x15-frdm.dts`
- Base source SHA-256: `f0576397b230a5a1ff5db11941a48deac9750b292832c420d46010843eb408c0`
- Generated FIT ITS SHA-256: `5df1af7be62819b1d549c0cc092f7c2356f551f6fda037d83302c798d9fdfedb`

This gate records what the aligned vendor device tree describes and what the
known-good partner build generated. It is not evidence that a driver probed or
that a physical peripheral worked.

## Base-board intent

| Requirement | NXP 6.12 DT evidence |
|---|---|
| HDMI | DPU, display pixel link, pixel interleaver, LDB channel 1, LDB PHY and IT6263 bridge at LPI2C4 address `0x4c` are enabled and linked to the HDMI connector |
| Ethernet | `enetc_port0` and `enetc_port1` are enabled; eMDIO PHYs at addresses 1 and 2 use PCAL6524 reset GPIOs 0 and 1 |
| IW612 Wi-Fi | USDHC3, power sequence, M.2 E-key power and WLAN reset/power GPIOs are described |
| IW612 Bluetooth | LPUART5 and the NXP Bluetooth child are enabled; firmware/runtime proof remains separate |
| IW612 802.15.4 | LPSPI3 and its chip-select are enabled; the product layer supplies the NXP Spinel consumer |
| Storage | USDHC1 is enabled as non-removable 8-bit eMMC; USDHC2 is enabled as removable 4-bit microSD with card detect and switched supply |
| USB | USB2 host has PCAL6524-controlled VBUS; USB3 DWC3 is dual-role and linked to the PTN5110 Type-C controller |
| Audio | MQS/SAI1 playback and PDM MICFIL capture are enabled |
| PCIe | PCIe0 is enabled with M.2 M-key supply, clock request and reset GPIO |
| CAN | FlexCAN2 and FlexCAN5 are enabled with the common transceiver/silent-mode supply |
| Companion core | CM7 remoteproc memory, MU7 mailboxes and RPMsg vrings are described and enabled |
| Board management | ADC1, PCAL6524, PCAL9554B, PCA9632 LEDs, SCMI thermal zones and watchdog 3 are enabled |

## Optional signed FIT configurations

The source naming is initially counter-intuitive: camera and Waveshare sources
are `.dtso` overlays, while `KERNEL_DEVICETREE` names composite `.dtb` outputs.
NXP's `freescale/Makefile` declares the `*-dtbs` inputs which combine the base
FRDM DTB, board overlay and, for OS08A20, the NeoISP overlay. Therefore these
are valid generated targets rather than missing source files.

The known-good build emitted non-empty base and composite DTBs, and its FIT ITS
contains nine configurations with `conf-imx95-15x15-frdm.dtb` as the default:

- base HDMI board;
- 8-microphone Rev E and audio-HAT variants;
- BOE WXGA LVDS and Waveshare 7-inch panel variants;
- AP1302 camera;
- single OS08A20 + NeoISP;
- OS08A20 combo + NeoISP;
- dual OS08A20 + NeoISP.

The generated composite DTBs are 92,557–97,385 bytes, not the 3–5 KiB overlay
fragments. This size distinction is retained as a regression clue.

## Known gaps and next evidence

The aligned base DTS contains no `pcf2131`, RTC or EEPROM node. NXP's public
board material proves those devices are fitted and I2C-connected, but not their
bus/address. Do not infer wiring. Obtain the gated design material or perform a
controlled bus inventory, then add machine-scoped nodes and preserve negative
and positive probe evidence.

After programming, the first-boot gate must confirm the running FIT config and
DT model, then match every enabled provider above against driver probe and the
requirement-specific physical test. Optional camera/panel configurations remain
build evidence until matching hardware is fitted and selected with `frdm_dtb`.
