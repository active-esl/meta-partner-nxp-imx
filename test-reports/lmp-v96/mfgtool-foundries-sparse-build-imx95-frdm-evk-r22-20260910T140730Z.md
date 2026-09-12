# FRDM-IMX95 Foundries sparse mfgtool build — r22

Date: 2026-09-10 14:07 BST  
Partner-layer revision: `344cb874c995851071d8077925b1281288377647`  
Machine: `imx95-frdm-evk`  
Distribution: `lmp-mfgtool` / LmP v96 integration gate

## Build result

The clean r22 checkout built `mfgtool-files` on `ai-tools` using the separate
mfgtool build directory and the established shared downloads/sstate cache.

```text
Tasks Summary: Attempted 2458 tasks of which 2417 didn't need to be rerun and all succeeded.
```

Build transcript SHA-256:
`ddf790fd266c507c3ee24757510129e5325422e7d5b58bc0362287a20d49c54a`

## Combined Foundries artifact gate

The production r8 deploy directory and the independently built r22 mfgtool
archive were verified together. This models Foundries' separate product and
mfgtools publication jobs rather than treating recovery artifacts as product
artifacts.

Result: `50 passed, 0 failed`.

The gate proves, among other checks:

- production WIC, OSTree repository/ref, FIT and `flash_a55` boot chain exist;
- display, Waydroid, IW612 and 802.15.4 packages are selected in the manifest;
- recovery and production boot-chain payloads are distinct;
- bundled UUU is the pinned i.MX95 AHAB-v2/V2X-capable build;
- the script performs native `all` target preflight;
- the WIC uses `flash -raw2sparse all`;
- both Foundries production bootloader slots are programmed;
- optional aligned WIC CRC verification remains a separate script;
- bundled UUU dry-parses both scripts successfully.

Combined gate transcript SHA-256:
`d0caf46baff9af1cc09993f9921463fac4c50aae5e3799e3d6ed7a749c3e534d`

## Programming bundle fingerprints

```text
f9f28b3c6972cd0d7398579ec6de320da959f6778571cbcc4750a72366d2e18f  lmp-factory-image-imx95-frdm-evk.wic.gz
0fa6438fb181dd0786bc0991b1d4dff2adbaf68d925d28045c6b2709264c5ebd  imx-boot-imx95-frdm-evk
18976b94fd770e12bf1cb747cc9c01a1b5d8e17612a29d3848d7e16bcbc49272  u-boot-imx95-frdm-evk.itb
d9777c8b8fed2286a80c9ff3aebe43c674ebbd4fbb6e338dea80e1b42e6a9d48  mfgtool-files-imx95-frdm-evk.tar.gz
6c8d72c1d06dea9b72aef7a96da0f98b330587a770f71e115afaa72bde7f1067  mfgtool-files-imx95-frdm-evk/full_image.uuu
```

The assembled bundle is retained on the development laptop as
`frdm-imx95-v96-product-r8-mfg-r22-foundries-sparse`.

Hardware programming and post-program boot verification are intentionally not
claimed by this report.
