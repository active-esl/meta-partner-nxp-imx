# FRDM-IMX95 v96 product build — iptables/netbase ethertypes clash

- Result: **FAIL — retained negative evidence; upstream fix backported**
- Build unit: `frdm-imx95-product-r5.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-partner12ab03f-distrof73d50a-bsp97cf68c-r5.log`
- Failure time: 2026-09-10 08:31:15 UTC
- Failing task: `lmp-factory-image-1.0-r0:do_rootfs`
- Task log: `/srv/yocto/frdm-imx95-product-v96-build/tmp/work/imx95_frdm_evk-lmp-linux/lmp-factory-image/1.0/temp/log.do_rootfs.33711`
- Terminal summary: 8,422 tasks attempted, 8,405 reused, exactly 1 failed
- Full log SHA-256: `ce1ab177d7407fcc3b783df744e789cea17ecfb68f51652b1b3635174e419d2b`

The preceding KMS correction is green: the build emitted and passed package QA
for `gstreamer1.0-plugins-bad-kms`, and the rootfs transaction found and began
installing the package. The transaction then failed because two packages own
the same path:

```text
Package iptables wants to install /etc/ethertypes
But that file is already provided by package netbase
```

The conflict is a known OE-Core regression introduced when iptables moved to
1.8.10. OE-Core fixed it by deleting the iptables copy because netbase is the
canonical owner. The exact upstream scarthgap backport is
`a970b6c927fb4c04473484f6e4b0a9853c8a5896`, which descends from the LmP v96
pinned OE-Core commit but is not present at that pin.

The NXP partner layer carries the same ownership correction only for
`mx95-nxp-bsp`, where adding the OTBR package group combines nft-enabled
iptables with netbase. This keeps the v96 compatibility workaround beside the
partner integration that exposes it and avoids masking the clash with package
manager force flags.

A retry must prove that the rebuilt iptables package no longer contains
`/etc/ethertypes`, netbase still provides it, and the rootfs package transaction
completes.
