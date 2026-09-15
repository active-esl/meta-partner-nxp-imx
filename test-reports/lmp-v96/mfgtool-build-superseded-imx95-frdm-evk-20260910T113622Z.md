# FRDM-IMX95 v96 partner-layer mfgtools build r16

- Result: **SUPERSEDED — build/static gates passed; bundled UUU is too old for the generated i.MX95 container**
- Partner source: `2f7d5838f4c30b44a066077d19e585902a9a7429`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-partner2f7d583-r16.log`
- Terminal summary: 2,458 tasks attempted, 2,446 reused, all succeeded
- Build-log bytes/SHA-256: 11,457 / `27a9dd4a2598322fb5cc57df6e907e46ef3e0ad569854a797019ff8322ff278f`
- Artifact verifier: 49 passed, 0 failed
- Verifier-log bytes/SHA-256: 3,284 / `e5691e19d8ac4eb8d855daf9a310ef8d8dd2d88befb0cf5a9f8daba9d84c3a11`

## Hardware result

The r16 archive has SHA-256
`68d5744538ad6ee95b252ac0972353e5e0f0e3215a911cff89b9330061ad12ec`.
Its recovery `flash_all` image is 2,479,104 bytes with SHA-256
`b0a6f2a0b86d1127265da50576ef1d801472f64364aec8bfcb8f7711b4a1bd3b`.
The generated scripts contained the proposed bounded-scan arguments and the
combined verifier passed, but the real programming attempt still failed at 35
percent during SDPS with `HID(W): LIBUSB_ERROR_IO`.

The 22,203-byte UUU transcript has SHA-256
`caeefc82a1a4a641f3a8eab488016a7a119862a928dc4a5b31e5b801e3789268`.
Kernel evidence records ROM `1fc9:015d` disconnecting at 12:36:25 BST, SPL1
SDPV `1fc9:0151` appearing one second later, then resetting to ROM after 25
seconds. No fastboot command or eMMC write occurred.

## Root cause

The archive still bundled UUU 1.5.179 (SHA-256
`2be8c39b3af0b20c0c9604035ea49965d664777fff6da60572ee61d8dd226319`).
The generated NXP 6.12 `flash_all` image uses AHAB container-header version 2
and includes a V2X header before the SPL container. UUU 1.5.179 predates both
code paths. NXP added container-v2 parsing in release 1.5.197 and V2X parsing
in 1.5.201. Without both, `GetContainerActualSize()` returns the entire image
at SDPS; SPL starts and removes the ROM endpoint while UUU is still writing.

Target 2901 remains the hardware control. Its successful programming flow used
the NXP FRDM `flash_all` image (SHA-256
`fdfb34eb080a4057ede674400644706a6f73c3635c0c510510a7c3bdfa73fde6`)
to reach fastboot, then programmed the Foundries partition image and firmware.
That proves the board and Foundries storage flow, but it was a hybrid recovery
path rather than a self-contained Foundries mfgtools artifact.

The next bundle must pin UUU 1.5.201 or newer for FRDM-i.MX95, retain the NXP
single-file SDPS/SDPV `-skipspl` flow, and prove `015d → 0151 → 0152` on the
board before any full WIC write is accepted.
