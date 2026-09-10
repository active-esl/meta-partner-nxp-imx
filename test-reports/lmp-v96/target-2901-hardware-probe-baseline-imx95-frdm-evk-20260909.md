# FRDM-IMX95 target 2901 hardware-probe baseline

- Board: physical `imx95-frdm-evk`
- Running image: `Linux-microPlatform Dynamic Devices 5.0.11-2901-95.2`
- Kernel: `6.6.52-lmp-standard`
- Companion baseline: ATF `lf-6.6.52-2.2.1`, OP-TEE
  `lf-6.6.52-2.2.1`, U-Boot `2024.04+fio`
- Serial capture: `/home/ajlennon/.local/state/hwlab/serial/frdm-imx95.log`
- Capture SHA-256: `a776a71fb84dd02f775db7319b62fa8c6b15a0eab855d82d2adb08cb0224f921`

## Result

Target 2901 proves the partial 6.6 port can reach Foundries userspace and
remains the boot/flash comparison point. It does **not** prove broad FRDM
hardware support. The final retained boot reports these unresolved probes:

```text
[   12.292646] platform usdhc3-pwrseq: deferred probe pending
[   12.297967] platform 42850000.mmc: deferred probe pending
[   12.303296] platform 42860000.mmc: deferred probe pending
[   12.308652] platform 428b0000.mmc: deferred probe pending
[   12.314024] platform regulator-ext-5v: deferred probe pending
[   12.319744] platform regulator-m2-pwr: deferred probe pending
[   12.325464] platform regulator-m2-mkey-pwr: deferred probe pending
[   12.331617] platform 42530000.i2c: deferred probe pending
[   12.336987] platform regulator-usdhc2: deferred probe pending
[   12.342710] platform 42540000.i2c: deferred probe pending
[   12.348084] platform regulator-usdhc3: deferred probe pending
[   12.353829] platform 44350000.i2c: deferred probe pending
[   12.359180] platform regulator-vbus: deferred probe pending
[   12.364722] platform 43810000.gpio: deferred probe pending
[   12.370189] platform 43820000.gpio: deferred probe pending
[   12.375645] platform 43840000.gpio: deferred probe pending
[   12.381106] platform 42590000.serial: deferred probe pending
[   12.392194] platform 4c200000.usb: deferred probe pending
```

These are related rather than eighteen independent faults: the unresolved I2C
and GPIO-expander chain supplies enables/resets to USDHC, IW612, USB and M.2
regulators. The new coherent 6.12 image must demonstrate that the dependency
chain settles before testing those consumers.

Additional negative baselines are:

```text
lvds_backlight_on: Cannot find pca9632 led dev
[    1.682533] usb_phy_generic usbphynop: dummy supplies not allowed for exclusive requests
[    1.701381] imx8mq-usb-phy 4c1f0040.phy: supply vbus not found, using dummy regulator
[    2.153007] pcieport 0002:01:01.0: of_irq_parse_pci: failed with rc=-22
[    2.278756]   No soundcards found.
[    6.251618] fsl-mqs mqs1: failed to get gpr node by phandle
```

The internal NETC fabric and both Ethernet functions enumerate in U-Boot, and
the first PCIe/NETC host bridge enumerates in Linux, but this is not cable/DHCP
or transfer proof. The second PCIe root-port interrupt parse failure is also
not proof that a fitted M.2 endpoint works.

Bluetooth has its own retained negative record because it progresses far
enough to create `hci0` before failing on absent firmware and protocol
timeouts. See
`target-2901-bluetooth-baseline-imx95-frdm-evk-20260909.md`.

## Replacement-image gate

After programming the aligned 6.12 image, require:

1. no final `deferred probe pending` lines for the named FRDM dependency chain;
2. all three USDHC hosts, eMMC, microSD and IW612 SDIO to enumerate;
3. real USB VBUS supplies and the intended Type-A/Type-C roles;
4. both NETC ports to pass carrier, DHCP and transfer tests;
5. sound cards for the intended MQS/PDM/HDMI paths, followed by playback and
   capture tests;
6. a fitted M.2 endpoint before promoting PCIe beyond controller metadata;
7. separate functional tests for GPIO expanders, PCA9632 LEDs, UART-backed
   Bluetooth, watchdog and every physically available interface.

Do not interpret disappearance of a log line alone as hardware proof; it only
advances the relevant item from the negative baseline to probe evidence.
