# FRDM-IMX95 v96 product build — missing GStreamer KMS package

- Result: **FAIL — retained negative evidence; fix staged**
- Build unit: `frdm-imx95-product-r4.service`
- Build log: `ai-tools:/srv/yocto/frdm-imx95-product-v96/imx95-v96-product-94abebf-12ab03f-bsp97cf68c-r4.log`
- Failure time: 2026-09-10 08:26:26 UTC
- Failing task: `lmp-factory-image-1.0-r0:do_rootfs`
- Task log: `/srv/yocto/frdm-imx95-product-v96-build/tmp/work/imx95_frdm_evk-lmp-linux/lmp-factory-image/1.0/temp/log.do_rootfs.176593`
- Terminal summary: 8,422 tasks attempted, 8,178 reused, exactly 1 failed
- Full log SHA-256: `f7de16ba8fe76ad96911eb89a29df5443e4aed3822995164b58abdb6ec06f441`
- Reviewed distro fix: `39af55f`
- Effective ai-tools distro commit: `f73d50a`

The rootfs package transaction failed because the display product feature
requires `gstreamer1.0-plugins-bad-kms`, but the NXP 1.26 recipe did not emit
that dynamic package:

```text
opkg_prepare_url_for_install: Couldn't find anything to satisfy
'gstreamer1.0-plugins-bad-kms'.
```

This is a build-time provider failure, not evidence that KMS is unnecessary.
The shared display product deliberately installs the DRM/KMS GStreamer sink,
and FRDM-IMX95 requires the same facility for HDMI pipelines. The NXP recipe
already appends `kms tinycompress` for `mx8-nxp-bsp`, but has no corresponding
i.MX95 override.

The focused fix appends `kms` to `PACKAGECONFIG` for `mx95-nxp-bsp`, causing
`libgstkms.so` and therefore `gstreamer1.0-plugins-bad-kms` to be emitted. It
was applied as a clean one-commit change on top of the exact consumed distro
revision rather than importing the older, divergent screen integration branch
where the fix was first developed.

A retry must prove the KMS plugin compiles, the dynamic package is written,
and the final rootfs transaction installs it successfully.
