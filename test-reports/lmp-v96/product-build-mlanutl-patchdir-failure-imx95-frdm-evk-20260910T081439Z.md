# FRDM-IMX95 v96 product retry — mlanutl patch-root failure

- Result: **FAIL — retained negative evidence; corrected fix validated**
- Build unit: `frdm-imx95-product-r3.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-12ab03f-bsp97394eb-r3.log`
- First error: 2026-09-10 08:14:39 UTC
- Terminal time: 2026-09-10 08:16:58 UTC
- Failing task: `mlanutl-git-r0:do_patch`
- Task log: `/srv/yocto/frdm-imx95-product-v96-build/tmp/work/cortexa55-lmp-linux/mlanutl/git/temp/log.do_patch.1301`
- Faulty staged BSP commit: `97394eb`
- Corrected reviewed BSP commit: `625d066`
- Terminal summary: 7,735 tasks attempted, 7,719 reused, exactly 1 failed
- Full log SHA-256: `4cf4a5ff0483c68147c0ddce37e5e6b2c822086d62c629c8b405b36596b007a3`

The first linker fix used repository-root paths in its patch:

```text
a/mapp/mlanutl/Makefile
```

However, the recipe sets `S = "${WORKDIR}/git/mapp/mlanutl"`, and BitBake's
patch task applies the patch from `S`. The patch therefore searched for a
second, nonexistent `mapp/mlanutl` path below `S` and failed with `No file to
patch` before compilation.

The corrected patch names `a/Makefile` and `b/Makefile`. Its diff payload was
fed directly to `git apply --check` from the exact ai-tools unpacked source
directory used by BitBake:

```text
/srv/yocto/frdm-imx95-product-v96-build/tmp/work/cortexa55-lmp-linux/mlanutl/git/git/mapp/mlanutl
```

That source-relative check passes. A further build must prove `do_patch`, the
link rule, GNU hash retention and `do_package_qa` together; the standalone
apply check is necessary but not sufficient proof.
