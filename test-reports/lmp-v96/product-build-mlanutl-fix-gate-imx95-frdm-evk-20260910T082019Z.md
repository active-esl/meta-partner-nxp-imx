# FRDM-IMX95 v96 product build — mlanutl linker fix gate

- Result: **PASS — recipe and ELF hardening gate**
- Build unit: `frdm-imx95-product-r4.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-12ab03f-bsp97cf68c-r4.log`
- Evidence time: 2026-09-10 08:20:19 UTC
- Reviewed BSP fix: `625d066`
- Effective ai-tools BSP HEAD: `97cf68c`

The corrected source-relative patch passed BitBake `do_patch`, and the recipe
then passed `do_compile`, `do_install`, `do_package`, `do_packagedata`,
`do_package_write_ipk` and the formerly failing `do_package_qa` task.

The actual final compiler invocation contains the Yocto linker policy:

```text
-Wl,--hash-style=gnu -Wl,--as-needed -Wl,-z,relro,-z,now
```

Direct `readelf -d` inspection of the resulting AArch64 executable reports:

```text
(GNU_HASH)
(FLAGS) BIND_NOW
(FLAGS_1) Flags: NOW PIE
```

The binary is a dynamically linked 64-bit AArch64 PIE. This closes the
specific `ldflags` QA defect. The full `lmp-factory-image` result remains a
separate gate and must reach a green terminal summary before this build is
accepted for programming.
