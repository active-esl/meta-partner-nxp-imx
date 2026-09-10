# FRDM-IMX95 v96 partner-layer mfgtools build r15

- Result: **PASS — clean-workdir recovery build, matched artifact gate and local USB preflight**
- Partner source: `4af6181c7ab4ffbc0e319c516d83d29a35d5f3f6`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-partner4af6181-r15.log`
- Terminal time: 2026-09-10 11:14:13 UTC
- Terminal summary: 2,458 tasks attempted, 2,405 reused, all succeeded
- Warnings: 8; version-selection and existing local-development warnings
- Build-log SHA-256: `3d9b4a9547a15ed7bd5dc1537e6713d114e31b874b73c6e86d1ddf1714b70d51`

The build used a clean task/work directory while reusing the established
downloads and sstate caches. This avoids the stale-source workdirs observed in
the earlier shared product/mfgtools workspace without discarding valid caches.

## M7 dependency correction

The first clean recovery attempt proved an NXP metadata defect that the
product graph had hidden. `IMX_M4_DEMOS` resolved correctly to
`imx-m7-demos:do_deploy`, but NXP's deferred expression was absent from the
final `imx-boot:do_compile[depends]` task flag. `imx-boot` consequently tried
to copy the FRDM M7 firmware before it had been deployed.

Partner commit `4af6181` adds the dependency explicitly and only when
`MACHINE` is `imx95-frdm-evk`. The resolved flag then contained
`imx-m7-demos:do_deploy`. A focused r14 preflight ran the M7 deploy before
`imx-boot`, and all 1,268 tasks succeeded. Its 16,149-byte log has SHA-256
`75c6f16936f3f0dae2e5db92e9fee82ea42962588f9ad0185bc3481eb2523f45`.

The r15 `imx-boot` log selects `flash_all` and records the real CM7 entry as
`m7_image.bin`, load address `0x303c0000`. The selected
`imx95-15x15-evk_m7_TCM_power_mode_switch.bin` is 37,084 bytes with SHA-256
`fe292f489c14738844c71693a65785842ade42cf0420bf58bc99a08c02ec078d`.
All five 15x15 M7 binaries selected for boot/runtime validation are non-empty.

## Matched programming artifacts

The r15 recovery archive was combined atomically with the green r8 Foundries
product output at:

`ai-tools:/srv/yocto/frdm-imx95-product-v96/programming/frdm-imx95-v96-product-r8-mfg-r15`

and copied unchanged to:

`/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r15`

The combined verifier passed 48 checks with no failures. It proves the full
Foundries WIC/OSTree/product set, expected display/Waydroid/IW612 packages,
recovery archive members, complete partition-programming script, separate
optional read-back script, distinct recovery/production boot payloads, and
successful UUU dry-runs. The 3,223-byte verifier log has SHA-256
`4997b84e1a4692cfaff4f2d7b1a5ca0dbef3002d476e00136ed81d6bafebec21`.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Product WIC gzip | 526,758,861 | `f9f28b3c6972cd0d7398579ec6de320da959f6778571cbcc4750a72366d2e18f` |
| Production `imx-boot` (`flash_a55`) | 2,592,768 | `0fa6438fb181dd0786bc0991b1d4dff2adbaf68d925d28045c6b2709264c5ebd` |
| Production U-Boot FIT | 1,716,370 | `18976b94fd770e12bf1cb747cc9c01a1b5d8e17612a29d3848d7e16bcbc49272` |
| r15 mfgtools archive | 37,802,738 | `cbefd34095d213564b68ad74cf3f83e76ca73929ad29e655e7b7fb82932f1da3` |
| Recovery `imx-boot` (`flash_all`) | 2,479,104 | `b0a6f2a0b86d1127265da50576ef1d801472f64364aec8bfcb8f7711b4a1bd3b` |
| Recovery U-Boot FIT | 1,519,406 | `53d6aebc1457788ad190696fbed194cab875327846a285177dab7a334009cae9` |
| Recovery FIT/initramfs | 33,264,284 | `3566c3836b3ad20292cd18012cbc7b9547a6657e9e1c8af9ac4b56e1089e3a70` |

`PROGRAMMING-SHA256SUMS` itself has SHA-256
`e9c55a1926d1d3806b5d7e2f8a49d0b09e70ae007b1401c4b6c1e60a8b526d77`.

## Local hardware preflight

The guarded local check revalidated every checksum and detected exactly one
i.MX95 BootROM device: `1fc9:015d`, serial `D38D0250C88A43CB`. A programming
attempt then stopped before UUU was launched because local `sudo` requires an
interactive fingerprint/password. Therefore no storage write is claimed by
this report. Full programming, boot and peripheral evidence remain open.
