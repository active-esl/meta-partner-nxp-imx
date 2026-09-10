# FRDM-IMX95 mfgtools pre-write poka-yoke — r24

Date: 2026-09-10

Result: **build and artifact verification pass; cold-ROM hardware run pending**

## Defect being prevented

The r22 recovery U-Boot exposed a `bootloader` raw partition of only
`0x60000` bytes.  The complete Foundries sparse WIC transfer therefore
finished before `FB: flash bootloader` rejected the 2.4 MiB production
container.  Existence-only `getvar` preflights did not detect that invalid
layout.

Commit `776b691d36d1c47ca7497403886defec7fb20f3a` makes the generated FRDM flow
fail before its first persistent write.  After selecting eMMC, it now:

1. requires all four redundant raw boot targets;
2. compares libuuu's live `getvar` responses with the intended layout:
   `bootloader` and `bootloader_s` = `0x400000`, `bootloader2` and
   `bootloader2_s` = `0x3a0000`, all type `raw`;
3. downloads the production container and FIT to RAM and uses U-Boot `itest`
   against their live `${filesize}` values; and
4. only then starts `flash -raw2sparse all`.

NXP UUU 1.5.201 stores a successful getvar result under an upper-case
`@NAME@` key.  Its conditional command executes `ucmd false` on a mismatch.
NXP U-Boot 2025.04 sets `${filesize}` when a Fastboot download completes and
returns failed `ucmd` status to UUU.  The checks therefore exercise the
actual recovery firmware and the actual production payloads without writing
the device.

The bundle assembler independently rejects an oversized production artifact
on the host and requires the entire preflight to occur before the WIC command.
The artifact verifier enforces the same contract.

## Clean mfgtools build

- Host: ai-tools (`192.168.68.55`)
- Checkout:
  `/srv/yocto/frdm-imx95-product-v96/meta-partner-nxp-imx-r24`
- Partner-layer revision: `776b691d36d1c47ca7497403886defec7fb20f3a`
- Kas file: `kas/lmp-v96-imx95-frdm-evk-6.12-partner-mfgtool.yml`
- Machine / distro: `imx95-frdm-evk` / `lmp-mfgtool`
- Tasks: 2458 attempted, 2446 reused, all succeeded
- Build log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-mfgtool-preflight-r24.log`
- Build-log SHA-256:
  `388bba40b0c3f9b74d5756cd02402e8818395f8d0626e076671712b28789d1b5`

The ai-tools virtual disk was expanded online from 1.5 TiB to 2 TiB before
the build.  Partition 3, the LVM PV/LV and ext4 were all extended; final
filesystem state was 2.0 TiB total, 519 GiB available, 74% used.

## Combined product r8 + mfgtools r24 verification

The partner verifier completed with **52 passes and 0 failures**.  This
included:

- production container size 2,592,768 bytes (limit 4,194,304);
- production FIT size 1,716,370 bytes (limit 3,801,088);
- exact live-layout and payload-size checks in generated `full_image.uuu`;
- UUU 1.5.201 dry parsing of programming and optional verification scripts;
- Foundries sparse whole-device WIC programming and both redundant boot sets;
- distinct recovery and production boot payloads; and
- existing product package/OSTree checks, including Weston, Waydroid and
  IW612 packages.

Evidence:

- Verification log:
  `/srv/yocto/frdm-imx95-product-v96/imx95-v96-combined-artifact-verify-r24.log`
- Verification-log SHA-256:
  `f6273c94933e31600a6b2edb234418b77bf6884f0e26b8bbaab5ca13e6be703b`
- Published mfgtools archive SHA-256:
  `71439bf67c0aa3ed8c406e9a5738ba114c68ecb5d0eab32c85e79f38a01a6430`

## Assembled operator bundle

Remote:

`/srv/yocto/frdm-imx95-product-v96/programming/frdm-imx95-v96-product-r8-mfg-r24-preflight`

Laptop:

`/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r8-mfg-r24-preflight`

All 12 entries in `PROGRAMMING-SHA256SUMS` passed after local transfer.

- Bundle size: 620,089,136 bytes
- `PROGRAMMING-SHA256SUMS` SHA-256:
  `8db88d8f503ae48f57993fed67598d9064ee37dd6c216eb35971fe32860cc9da`
- Generated `full_image.uuu` SHA-256:
  `872334ae178ad40d77742b61962647248a2aa4b8bec8d6d8ddfc39a8a42e0bc7`

## Remaining hardware gate

Run the guarded r24 bundle from a cold i.MX95 BootROM identity, proving the
entire ROM -> SPL -> recovery Fastboot -> preflight -> persistent programming
sequence.  Then switch to normal eMMC boot, cold-cycle, capture an ungarbled
serial log and verify the programmed Foundries image boots.  Optional WIC
read-back remains a separate operator action.
