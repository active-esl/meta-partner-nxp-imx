# FRDM-IMX95 v96 product build — mlanutl QA failure

- Result: **FAIL — retained negative evidence; fix prepared**
- Build unit: `frdm-imx95-product-r2.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-dfb3168-367817d-r2.log`
- First error: 2026-09-10 07:44:05 UTC
- Terminal time: 2026-09-10 08:12:28 UTC
- Failing task: `mlanutl-git-r0:do_package_qa`
- Task log: `/srv/yocto/frdm-imx95-product-v96-build/tmp/work/cortexa55-lmp-linux/mlanutl/git/temp/log.do_package_qa.3592915`
- Prepared BSP fix: `0f878d3` (`mlanutl: retain Yocto linker hardening flags`)
- Terminal summary: 8,180 tasks attempted, 2,718 reused, exactly 1 failed
- Full log SHA-256: `a4bfb705f07534565f105b4af66eae3ad976fa10a3de1f66620b861d1403e055`

The binary contained a SysV `HASH` dynamic tag but no `GNU_HASH`, causing the
fatal Yocto `ldflags` QA check. The recipe passed the distribution `LDFLAGS`,
including `--hash-style=gnu` and RELRO/NOW, but NXP's utility Makefile linked
with only:

```text
$(CC) $(LIBS) -o $@ $(OBJECTS)
```

The prepared patch changes the actual link rule to:

```text
$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBS)
```

It also replaces `SRCREV = "${AUTOREV}"` with the exact revision consumed by
the failed build, `4cc2c8831f27c8eceece6b66fc2de8b73360f520`, from NXP's
`lf-5.15.71_2.2.0` utility branch. NXP's aligned `mwifiex` 6.12 driver tree
contains only the kernel driver and does not ship `mapp/mlanutl`, so this is a
deliberate, pinned userspace compatibility exception rather than an accidental
mixed kernel driver.

The patch passes `git apply --check` against the exact failed source checkout.
The original build subsequently reached terminal after its remaining Node/V8
compile completed successfully. This does not yet prove the fix: stage the BSP
commit, rebuild `mlanutl`, require `GNU_HASH` in the packaged binary and a green
`do_package_qa`, then resume the full Factory image.

The transient systemd unit reports `Result=success` because the
`kas-container` wrapper itself returned zero; the authoritative KAS log records
BitBake's non-zero exit, the one-task failure summary and the error above.
