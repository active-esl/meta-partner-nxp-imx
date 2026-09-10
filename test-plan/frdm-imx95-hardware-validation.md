# FRDM-IMX95 hardware validation

Machine: `imx95-frdm-evk` · baseline: Foundries LmP v96 + NXP
`lf-6.12.49-2.2.0`

This is the requirement-to-evidence gate for the partner-layer port. A recipe
building, a driver being configured, and a peripheral working on the bench are
three separate claims. Do not promote a row to **hardware proven** without a
saved command result or serial-log reference.

## Evidence states

- **metadata** — recipe, provider and image dependency graph is correct;
- **built** — the exact pinned Factory configuration emitted the artifact;
- **booted** — the driver probed on FRDM-IMX95 without a blocking error;
- **hardware proven** — the physical interface completed its functional test.

Keep generated results in `test-reports/<lmp-release>/`. Keep complete serial
logs locally; reference their path and SHA-256 in the committed test record.

## Requirements matrix

| Requirement | BSP intent | Hardware proof |
|---|---|---|
| Boot chain | 6.12 NXP component set; FRDM DT; Foundries split `imx-boot`/FIT flow | Cold boot from programmed eMMC; no reset loop; record SPL, U-Boot, System Manager, TF-A, OP-TEE and kernel banners |
| Foundries storage/update | i.MX95 GPT/WIC layout, OSTree, U-Boot environment, optional UUU verification | Program full mfgtools bundle, boot, OTA forward, forced failure, rollback, then OTA forward again |
| HDMI/Weston | DPU → pixel-link → LDB → IT6263 → HDMI; product selects `display` | With monitor on J17, connector is `connected`, EDID mode exists, Weston runs and renders GLES |
| Waydroid | Product selects `android-container`; binder, graphics and networking included | Container starts, Android UI appears over HDMI, ADB responds, DNS/HTTPS works, survives reboot |
| Ethernet | Both NETC RGMII ports and PHY reset GPIOs enabled | Cable each RJ45 in turn; carrier, DHCP, ping and sustained transfer on `end0` and `end1` |
| IW612 Wi-Fi | USDHC3, `mlan`/`moal`, aligned secure firmware | Scan, associate on 2.4 and 5 GHz, DHCP, HTTPS and sustained transfer |
| IW612 Bluetooth | LPUART5 + NXP HCI attach/firmware | `hci0`, scan, pair and exchange data/audio with a known peer |
| IW612 802.15.4 | LPSPI3/interrupt/reset transport plus NXP `otbr-agent-iwxxx` from the matching `meta-nxp-connectivity` release | Spinel radio starts, `wpan0` appears, and exchanges frames with a known Thread peer |
| eMMC/microSD | USDHC1 HS400 + USDHC2 UHS/card detect | Identify eMMC, insert/remove SD, mount, write/read/verify a disposable test file |
| USB | USB2 Type-A host; USB3 Type-C dual-role/Type-C controller | Enumerate known USB2 and USB3 devices; prove intended Type-C role transition |
| Audio | MQS jack, PDM microphones and HDMI audio | Capture PDM audio; play known samples through jack and HDMI |
| PCIe | M.2 Key-M regulator/reset and PCIe root complex | Fit known NVMe/device, enumerate with `lspci`, run read/write smoke test |
| CAN | FlexCAN2/5 and board transceivers | Wire a second CAN node/loop, send and receive on every exposed intended port |
| Camera/ISP | Signed optional NXP camera DTBs in FIT; media/ISP/VPU kernel support | Select matching DTB, enumerate supported camera, preview through ISP to HDMI |
| VPU/GPU/NPU | Amphion/media, DRM/GPU userspace and eIQ Neutron support | Decode known clip, render GLES, run known NPU model and save timing/output |
| M7/M33 | System Manager M33 boot plus Linux M7 remoteproc/RPMsg | Confirm M33 banner; load known M7 firmware and exchange RPMsg round trip |
| Board peripherals | PCAL GPIO expanders, PCA9632 LEDs, ADC, thermal and watchdog are described by the NXP 6.12 DT; the on-board PCF2131 RTC and EEPROM are a known DT gap pending schematic/bus confirmation | Read RTC/EEPROM/ADC/temp; exercise spare GPIO/LED; controlled watchdog reboot |

The NXP `lf-6.12.49-2.2.0` FRDM device tree, and the current upstream
`lf-6.12.y` tree checked on 2026-09-10, do not instantiate the PCF2131 or
EEPROM advertised for the board. Do not guess their I2C bus/address: confirm
them from UM12472/design files or a controlled bus scan, then add a
machine-scoped DT patch and retain the negative/positive probe evidence.

Target 2901 is the known-good boot/flash reference, not a claim that every
interface worked. Its retained serial log is the negative Bluetooth baseline:
`btnxpuart` could not find `nxp/uartspi_n61x_v1.bin.se` and subsequently timed
out. The aligned 2.2.0 firmware package contains that exact image; require both
rootfs presence and a clean functional radio test after programming.

## Initial build gate

The exact pinned v96 partner KAS configuration must complete before hardware
programming:

```sh
kas-container build kas/lmp-v96-imx95-frdm-evk-6.12-partner-mfgtool.yml
kas-container build kas/lmp-v96-imx95-frdm-evk-6.12-partner-thread.yml
kas-container build kas/lmp-v96-imx95-frdm-evk-6.12-partner.yml
```

Record hashes and sizes for the WIC, OSTree, FIT, `imx-boot`, mfgtools archive,
UUU scripts and every file consumed by the UUU scripts. Confirm that the normal
script performs the full write and that verification is a separate optional
operation.

Foundries publishes the production image and mfgtools as separate build runs.
Preserve that separation locally too. If local gates deliberately share one
`KAS_BUILD_DIR`, run the mfgtool gate before the production Factory gate: both
providers deploy generic `imx-boot-${MACHINE}` and `u-boot-${MACHINE}.itb`
links, so the last provider built owns those links. Immediately before UUU,
require the external production `imx-boot-${MACHINE}` link to resolve to
`flash_a55`, require its hash to differ from the bundled `imx-boot-mfgtool`
`flash_all` container, and require the external U-Boot FIT to differ from the
bundled mfgtool FIT. A successful mfgtools build followed directly by flashing
from its shared deploy directory can otherwise install recovery boot payloads
in the production boot slots.

For i.MX95, also prove that the mfgtool `flash_all` container was assembled
with NXP's real 15x15 M7 payload. In the `imx-boot` task log, retain the
`m7_image.bin` source/name and container entry; in deploy output, require the
selected `mcore-demos/imx95-15x15-evk_m7_TCM_power_mode_switch.bin` and every
M7 firmware named by `IMAGE_BOOT_FILES` to exist and be non-empty. A successful
build made possible by a zero-byte placeholder is a negative result, not a
valid manufacturing artifact.

The Thread gate pins NXP `meta-nxp-connectivity` at the exact
`rel_imx_6.12.49_2.2.0` commit. Its OTBR and Zigbee RCP Scarthgap declaration
patches and `radvd` static UID allocation are compatibility work that must
remain explicit and tested. Foundries' deterministic-user policy turns an
otherwise late rootfs failure into a provider-resolution error; add any future
NXP daemon account to the partner table rather than disabling
`useradd-staticids`.

Scarthgap's mDNSResponder 2200 header does not declare
`kDNSServiceErr_StaleData`, while the pinned NXP `otbr-iwxxx` source refers to
it in two switch cases. The partner patch removes only those unreachable cases.
Retain the negative compile log, then require `otbr-iwxxx:do_compile`, package
generation and the complete `packagegroup-nxp-otbr` gate to pass. Re-audit this
patch rather than carrying it blindly when either source revision changes.

That connectivity release also appends a patch which removes old systemd's
explicit rejection of router advertisements received from the interface's own
link-local address. LmP v96 uses systemd 255, whose refactored `sd-ndisc`
already has no such rejection. Remove the obsolete patch only for
`imx95-frdm-evk`; do not force it onto the new source and do not lose the
intended same-interface RA behaviour.

### Product metadata gate

Before spending a full image build or a board-programming cycle, resolve the
actual product KAS configuration with `bitbake -e lmp-factory-image` and retain
the generated environment's hash. For the HDMI + Waydroid product, require all
of the following in the effective values rather than only in source comments:

- `DD_PRODUCT_FEATURES` contains both `display` and `android-container`;
- the Android package group resolves to `waydroid`, and the Waydroid recipe is
  compatible with `imx95-frdm-evk`;
- Wayland, OpenGL, Vulkan and the host audio features required by Waydroid are
  present;
- Weston/Wayland, IW612 firmware/tools, Zigbee RCP and NXP OTBR are in the
  image dependency graph;
- the machine-scoped Binder/BinderFS fragment is in the selected kernel's
  source URI;
- i.MX8MM panel rotation and fixed DRM-card policy do not leak onto FRDM HDMI.

This is a metadata gate only. It prevents avoidable long builds but cannot be
promoted to built, booted or hardware-proven evidence.

### Provider audit note

Audit the component actually present in the image task graph, not merely every
similarly named recipe that BitBake can parse. `imx-boot` includes the
`imx-mkimage` source and, for this machine, is pinned to
`lf-6.12.49_2.2.0`. The standalone `imx-mkimage-native` recipe is not in the
v96 `lmp-factory-image` dependency graph. A machine override on that native
recipe is ineffective because native recipes do not carry machine overrides;
do not reinstate one or treat its default 6.6 version as boot-container
evidence.

The i.MX95 U-Boot tools recipe has `DEFAULT_PREFERENCE = "-1"` and is selected
explicitly for `mx95-nxp-bsp`. This prevents its higher version from silently
changing established i.MX6/i.MX8/i.MX93 builds.

Do not infer that NXP's userspace UAPI package must have the same version as
the running kernel. In the exact `lf-6.12.49-2.2.0` `meta-imx` release,
`linux-imx-headers_6.6` is intentionally retained for multimedia consumers and
exports `imx/linux/mxc_asrc.h`; the 6.12 kernel tree no longer exports that
header. A local 6.12 replacement built successfully in isolation but caused
`imx-alsa-plugins` to fail when the full image rebuilt. The provider/version
gate is therefore the exact vendor release metadata plus a consumer compile,
not numerical version equality.

## First boot run

Keep serial capture independent from programming and resilient to USB ACM
renumeration. Start the capture before power/boot and save the full log. With
HDMI, IW612 and the second Ethernet port connected, run on the target:

```sh
sudo ./interface-test-imx95-frdm-evk.sh \
  --require-hdmi --require-wifi --require-thread --require-second-ethernet \
  | tee interface-test-results-imx95-frdm-evk-$(date -u +%Y%m%dT%H%M%SZ).md
```

For the product image, add the Waydroid hard gate:

```sh
sudo ./interface-test-imx95-frdm-evk.sh \
  --require-hdmi --require-waydroid --require-wifi --require-thread \
  --require-second-ethernet
```

The script is a discovery/regression sweep, not the whole acceptance test. Its
SKIP rows identify peripherals that need fitting or deliberate destructive
testing. Close every required SKIP with the manual proof in the matrix above.

## Failure triage order

1. Identify the first failing boot stage from the serial log; do not debug a
   later Linux symptom through a preceding U-Boot reset.
2. Confirm the running DTB and component versions match the exact build.
3. Separate missing hardware, missing kernel driver, deferred probe and missing
   userspace/firmware packaging.
4. Change one provider/configuration cause at a time and retain the negative
   evidence; a fast or apparently successful UUU run is not proof of a full
   image write.
5. Re-run the smallest build gate, then the full Factory image, mfgtools build,
   programming and physical test in that order.
6. Prefer the vendor's coherent companion-core dependency graph over a local
   placeholder. The 2.2.0 `meta-imx` layer already makes `imx-boot` depend on
   `imx-m7-demos:do_deploy` for mx95 and copies `M4_DEFAULT_IMAGE_MX95` into
   `flash_all`; bypassing that path hid missing M7 support while making the
   container appear buildable.
7. Keep KAS includes repo-relative (`kas/...`), as KAS 4.7 recommends. A
   sibling filename only works through its file-relative compatibility
   fallback, and a source-only snapshot mounted with `kas/` as the repository
   root incorrectly turns `kas/...` into `kas/kas/...`. Run derived gates from
   a real Git-root checkout (the staged ai-tools partner checkout). The v96
   base config resolves `meta-partner-nxp-imx` from kas-container's explicit
   `/repo` Git-root mount, while `KAS_WORK_DIR` and `KAS_BUILD_DIR` can point at
   a reusable cache workspace. Never mirror the partner checkout onto
   `KAS_WORK_DIR` with deletion enabled: that root also owns KAS's pinned
   dependency checkouts and may own generated BitBake work/stamps. A config
   using `path: .` resolves the partner layer from `/work`, not `/repo`, when
   those mounts differ; this can silently build a stale source snapshot.
   NXP's matching OTBR recipe is deliberately unversioned
   (`otbr-iwxxx.bb`), so its partner append must also be unversioned
   (`otbr-iwxxx.bbappend`); a version-wildcard `_%.bbappend` is dangling and
   must remain a hard parse failure.
8. A derived distro can change a virtual provider's name without changing its
   implementation. Foundries' generic TA-devkit recipe recognises
   `optee-os-fio`, while `lmp-mfgtool` selects `optee-os-fio-mfgtool`; make the
   4.8 devkit inherit the same OP-TEE build explicitly for that provider and
   keep the NXP source revision/patch tuple shared with the runtime recipe.
