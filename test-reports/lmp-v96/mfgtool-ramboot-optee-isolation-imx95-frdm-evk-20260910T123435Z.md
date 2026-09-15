# FRDM-i.MX95 mfgtool RAM-boot OP-TEE isolation

Date: 2026-09-10

## r17 hardware result

The `r17` recovery artifact used bundled `libuuu_1.5.201`.  That corrected the
earlier host-side AHAB-v2 transfer failure: USB progressed from ROM
`1fc9:015d` to SPL `1fc9:0151`, and SPL downloaded and jumped to the 1,567,744
byte second-stage container.  Serial then stopped after:

```text
NOTICE:  BL31: v2.12.0(release):lf-6.12.49-2.2.0-dirty
NOTICE:  BL31: Built : 10:13:07, Oct 17 2025
```

The device never enumerated as fastboot `1fc9:0152`.  This narrows the failure
from ROM/UUU/SPL to the BL31 -> BL32/U-Boot hand-off.  The RAM-only test made no
eMMC changes, retaining target 2901 as the known-good installed baseline.

## r18 diagnostic configuration

For the mfgtool distro only, `optee` was removed from `MACHINE_FEATURES` so the
recovery container can isolate the BL32 hand-off.  The production configuration
continues to include OP-TEE.

The first incremental r18 artifact was rejected before hardware use.  Although
the OP-TEE tasks disappeared, `imx-mkimage` retained `${BOOT_STAGING}/tee.bin`
from the prior build and silently repacked it.  This was exposed by inspecting
the `imx-boot:do_compile` container manifest rather than relying on task counts
or archive size.

The partner layer now removes stale `tee.bin` and `tee.bin-stmm` before an
OP-TEE-free i.MX95 `do_compile`.  `imx-boot` was then explicitly cleansstated and
the mfgtool target rebuilt.

## r18b intermediate evidence

The r18b application container had two images: BL31 at `0x8a200000` and
U-Boot at `0x90200000`, with no image at the OP-TEE load address `0x8c000000`.
Its RAM-only hardware test nevertheless stopped after the same BL31 banner as
r17 and did not enumerate fastboot.

Post-test comparison showed that r18b's authenticated BL31 payload was
byte-identical to r17. The evaluated BitBake variables requested a non-OP-TEE
ATF build, but the task log said:

```text
make -j 20 ... DEBUG=0 bl31
make: Nothing to be done for 'bl31'.
```

ATF's generated build tree had retained the earlier `SPD=opteed` output. Thus
r18b paired no BL32 with an old opteed BL31 and is rejected as an OP-TEE
isolation result.

The ATF recipe now declares `${S}/build` as a `do_compile[cleandirs]` path so a
task signature change reconstructs BL31 with the evaluated configuration. Both
`imx-atf` and `imx-boot` were cleansstated before the r18c build.

## r18c corrected clean-build evidence

- Build host: `ai-tools`
- Kas configuration: `kas/lmp-v96-imx95-frdm-evk-6.12-partner-mfgtool.yml`
- Tasks: 2,189 attempted; all succeeded
- Log: `/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-nooptee-r18c.log`
- ATF log confirms a real non-SPD compile and a newly built `bl31.bin`
- Archive SHA-256: `77e9847fc65e478d6dfbef5f36930e6289d35f293781cd585b109e10882ff527`
- Archive size: 30,590,292 bytes
- `imx-boot-mfgtool` SHA-256: `34f3250622484f951ad46ad8e1f9b2a9d51928315120a69ac19324effc4a27d4`
- `imx-boot-mfgtool` size: 1,847,296 bytes
- r17 BL31 payload SHA-256: `a00f32134431e87e2129047e7e3bd32f54d147a373f3fdc84a82cf07d09f9195`
- r18c BL31 payload SHA-256: `ba3d590a2d2444f0f66cdbbd8a0a10cb02560b8b13e428d243dffe7995c503b1`
- Bundled UUU script dry parse: PASS
- Media-write safety scan: PASS

The RAM-only hardware test passed.  UUU completed `FB: ucmd version` and
`FB: done` with `Success 1 / Failure 0`, and the board enumerated as the NXP
USB download gadget `1fc9:0152`.  This proves the complete
ROM -> SPL -> non-SPD BL31 -> U-Boot fastboot path.  No eMMC write command was
present, so the installed target-2901 baseline remained untouched.

## Coherency and reference-container audit

NXP's primary `meta-imx` `walnascar-6.12.49-2.2.0` branch was inspected at
commit `1cfbbb8f9ce1d6071775ea6083b79d98597c8206`.  The partner-layer pins match
the release metadata exactly:

| Component | Revision |
| --- | --- |
| imx-mkimage | `be80fadd5e7988214149a2bc48daac1b0950d4c2` |
| U-Boot | `4ddbad60eff308a5b356fb9ab8734ac382ddd692` |
| ATF | `a266ff458c2526a6474036a5c6648be6fdc54fe3` |
| System Manager | `de30901b287e5c9a1e467d2d9a497b97bb6f7939` |
| OEI | `49bfaa93e9d1fe213866bcb9507927a59a9ede5a` |
| OP-TEE | `771a7ca0494110b5eee1229cc175c755ab8c7e00` |
| ELE firmware | `93492e0` |

The NXP LF 6.18.2 FRDM `flash_all` image previously used in the target-2901
programming flow was parsed as an independent known-good layout reference.  It
also contains BL31, U-Boot and OP-TEE at the same three load addresses as r17.
Therefore OP-TEE's presence and the monolithic `flash_all` layout are not by
themselves defects.

NXP's recipe links `tee.bin` to `tee-raw.bin`, while the inherited Foundries
recipe links it to `tee-pager_v2.bin`.  This initially appeared material, but
for the current `CFG_WITH_PAGER=n` i.MX95 build those two files are byte-for-byte
identical (SHA-256
`399a26302cda41bf80a3b4e99aa7a3c16b73c40868581a57e324979f887295ba`).
That packaging difference is consequently ruled out for r17.

The remaining OP-TEE-side delta is the forward-ported Foundries security patch
and Foundries build flags.  Since r18c proved that a matched non-SPD BL31 and
no-BL32 container reaches U-Boot, r19 is the narrower unpatched NXP OP-TEE
comparison.

The corrected bundle is:

```text
/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r18-nooptee-diagnostic
```

## r19 unpatched NXP OP-TEE comparison

The r19 build restores OP-TEE in `MACHINE_FEATURES` but removes
`0001-optee-retain-foundries-security-pkcs11-delta.patch` for `mx95-nxp-bsp`.
It explicitly cleansstated OP-TEE, ATF and imx-boot before rebuilding.

Build and packaging evidence:

- ATF performed a real clean compile with `SPD=opteed`; the log includes
  `Including services/spd/opteed/opteed.mk` and a newly linked `bl31.bin`.
- OP-TEE `do_patch` completed with no patch application, confirming this is the
  coherent NXP source baseline rather than the Foundries-patched variant.
- Tasks: 2,458 attempted; all succeeded (10 non-fatal warnings).
- Build log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-optee-nxp-r19.log`.
- Archive SHA-256:
  `44e0eaa37f5f281186a73c709f390b5a137f6335a44dd7e3deccbe4f50953493`.
- `imx-boot-mfgtool` SHA-256:
  `7e5b515194f2cc5a46056187a14ec60e7cd558be6df4f69a3f6c3c421ec29385`.
- `imx-boot-mfgtool` size: 2,483,200 bytes.
- The imx-boot log records an AHAB container-header version 2 application
  container with BL31 at `0x8a200000`, U-Boot at `0x90200000`, and OP-TEE at
  `0x8c000000`.
- Bundled UUU 1.5.201 dry parse: PASS.
- Diagnostic bundle:
  `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r19-optee-nxp-diagnostic`.

The RAM-only hardware test downloaded and jumped to the 1,571,840-byte r19
application container. Serial reached the clean `SPD=opteed` BL31 banner, then
stopped. The board did not enumerate as fastboot `1fc9:0152`, and the bounded
observation period produced no further serial output. The waiting UUU process
was terminated after the unchanged observation; no media-write command was
present and eMMC remained untouched.

This rules out the Foundries security patch as the cause: both the patched r17
and unpatched r19 OP-TEE builds fail at the same BL31 -> BL32 boundary.

## Earlier working-build comparison and r20 hypothesis

The May working Foundries build is a distinct, older baseline rather than an
earlier instance of the current 6.12 stack. Its retained build log identifies:

- Foundries LmP `5.0.11` / Scarthgap
- NXP `scarthgap-6.6.52-2.2.1` at `e83d4402acde050d2b2761995761c81c797b5b03`
- U-Boot `imx-2024.04`
- OP-TEE `4.4.0-imx`
- BSP commit `aaca64a16a254c4d6166d7669bec9cc5b081b54b`

That BSP did force `CFG_DT=y CFG_EXTERNAL_DTB_OVERLAY=y
CFG_DT_ADDR=0x83200000` for the i.MX95 mfgtool OP-TEE build, so those settings
were compatible with the older stack and cannot alone explain every failure.
However, NXP's official `walnascar-6.12.49-2.2.0` OP-TEE recipe does not apply
them to i.MX95. The current partner layer added the i.MX95 stanza by copying the
i.MX93 settings; it is not sourced from the 6.12 NXP release metadata.

The r20 test therefore restores the Foundries security patch and removes only
that unsupported i.MX95 OP-TEE override from both production and mfgtool
configuration. This preserves OP-TEE and tests the exact 6.12 NXP platform
default at the isolated failure boundary.

## r20 build evidence

- Tasks: 2,458 attempted; 2,373 reused; all succeeded.
- Build log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-optee-nxp-defaults-r20.log`.
- Evaluated `SRC_URI` contains the Foundries security patch, and `do_patch`
  records that it was applied.
- Evaluated `EXTRA_OEMAKE` contains `PLATFORM=imx-mx95evk` but no forced
  `CFG_DT_ADDR` or external-DT arguments.
- OP-TEE 4.8's own i.MX platform defaults still enable DT and external overlay;
  the material change is that the partner layer no longer overrides BL31's DT
  hand-off with the copied i.MX93 address `0x83200000`.
- The AHAB application container contains clean SPD BL31 at `0x8a200000`,
  U-Boot at `0x90200000`, and patched OP-TEE at `0x8c000000`.
- Archive SHA-256:
  `3a98e0e522d1be7aa7353cbb29b1d42cfdd335d3c1a76ec536fe59827f5a3c21`.
- `imx-boot-mfgtool` SHA-256:
  `9cd83a3e4d9f484dd0a0ba4ed4af6fe773bde659ad8ba50989b60d971cde6341`.
- Bundled UUU 1.5.201 dry parse: PASS.
- RAM-only media-write safety scan: PASS.
- Diagnostic bundle:
  `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r20-optee-nxp-defaults-diagnostic`.

## r20 hardware result

The board entered the test from i.MX95 ROM USB mode `1fc9:015d`. UUU downloaded
the full 1,572,864-byte second-stage container, jumped it, enumerated U-Boot
fastboot `1fc9:0152`, and completed `FB: ucmd version` plus `FB: done` with
`Success 1 / Failure 0`.

Serial proves the complete secure boot hand-off:

```text
NOTICE:  BL31: v2.12.0(release):lf-6.12.49-2.2.0-dirty
I/TC: Non-secure external DT found
I/TC: OP-TEE version: 3.16.0-3381-g771a7ca04-dev+fio
I/TC: Primary CPU switching to normal world boot
U-Boot 2025.04-g4ddbad60eff3-dirty
Model: NXP FRDM-IMX95 board
Detect USB boot. Will enter fastboot mode!
```

USB after the test was `1fc9:0152 NXP Semiconductors USB download gadget`.
The host UUU log SHA-256 is
`e8436b2d051d6cc8905d14313aa977cd52836091470dc2154bff5faa712a268f`.
The RAM-only script made no eMMC changes, so target 2901 remains the installed
known-good baseline.

This verifies the 6.12 mfgtool secure boot chain with OP-TEE enabled and the
Foundries security patch retained. The regression was the partner layer's
forced i.MX93 DT address, which overrode the i.MX95 BL31 hand-off. Removing
that override is the maintainable NXP-aligned fix.
