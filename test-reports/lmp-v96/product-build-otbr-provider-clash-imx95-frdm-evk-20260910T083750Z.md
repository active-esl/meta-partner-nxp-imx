# FRDM-IMX95 v96 product build — generic/IWxxx OTBR provider clash

- Result: **FAIL — retained negative evidence; provider policy fixed**
- Build unit: `frdm-imx95-product-r6.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-partner376e90a-distrof73d50a-bsp97cf68c-r6.log`
- Failure time: 2026-09-10 08:37:50 UTC
- Failing task: `lmp-factory-image-1.0-r0:do_rootfs`
- Task log: `/srv/yocto/frdm-imx95-product-v96-build/tmp/work/imx95_frdm_evk-lmp-linux/lmp-factory-image/1.0/temp/log.do_rootfs.25645`
- Terminal summary: 8,422 tasks attempted, 8,403 reused, exactly 1 failed
- Full log SHA-256: `31776e70ac1a935921c703123973c112233accc29bfade6452c962a5b4b0dd27`

The previous ownership fix is green: rebuilt iptables no longer contains
`/etc/ethertypes`, netbase remains its sole provider, and rootfs assembly moved
past that path. The next transaction failure showed that NXP's OTBR package
group directly depends on generic `otbr` and, when `has-iwxxx` is present, also
adds `otbr-iwxxx`.

Those are alternative implementations, not co-installable companions. Their
packages overlap on the D-Bus policy, `otbr-agent.service`, `otbr-web.service`,
the web server and its complete frontend. The IWxxx package supplies the
hardware-specific `otbr-agent-iwxxx`, `ot-ctl-iwxxx` and IW612 SPI setup script;
the generic package supplies the UART-oriented agent.

FRDM-IMX95 uses its onboard IW612 SPI RCP. The partner policy therefore removes
generic `otbr` from `packagegroup-nxp-otbr` for `mx95-nxp-bsp`, retaining
`otbr-iwxxx` and `tayga`. It does not suppress file-clash checks or arbitrarily
overwrite one provider with the other.

A retry must prove the package group's evaluated runtime dependencies contain
`otbr-iwxxx` but not generic `otbr`, and that final rootfs assembly succeeds.
