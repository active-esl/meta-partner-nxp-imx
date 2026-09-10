# FRDM-IMX95 IW612/Thread build gate

- Gate time: `2026-09-10T04:45:27Z`
- Machine: `imx95-frdm-evk`
- Target: `packagegroup-nxp-otbr`
- Configuration: `kas/lmp-v96-imx95-frdm-evk-6.12-partner-thread.yml`
- KAS: `4.7`
- Build host: `ai-tools`
- Staged partner commit: `0efbe51827b43fa076ec60c219c8746da04e5042`
- Local content-equivalent commit: `fa8d0b4`
- Shared tree: `22e1952e1023011de84ede13a8b1d5129772c89a`
- `meta-nxp-connectivity`: `14a32aa7467f58257e3bb93a5c0fa443c70ae1ae`

## Positive result

BitBake attempted 3,200 tasks; 3,176 were current and every task succeeded.
The changed `otbr-iwxxx` path ran `do_fetch`, `do_unpack`, source revision
reset, `do_patch`, `do_configure`, `do_compile`, `do_install`, `do_package`,
`do_packagedata` and `do_package_write_ipk` successfully. The work tree no
longer contains either unsupported `kDNSServiceErr_StaleData` case.

Primary outputs:

| Output | SHA-256 |
|---|---|
| `packagegroup-nxp-otbr_1.0-r0_all.ipk` | `5ae05c705325a8f116d7d8da3ccc0e667300e392763381b0a4fb8cf44c6e45fd` |
| `otbr-iwxxx_1.0-r0_cortexa55.ipk` | `50fe6a14043b3608c2b0fa3bd236545c443587ed82813b5702caa047f1395f28` |

The package metadata retains `packagegroup-nxp-otbr` dependencies on `otbr`,
`otbr-iwxxx` and `tayga`. `otbr-iwxxx` retains its runtime dependency on
`radvd`; the generated `radvd` metadata contains the deterministic static
`radvd` UID 966 and `nogroup` GID 65534 introduced by the compatibility port.

The separate production deploy invariant also remains intact:
`imx-boot-imx95-frdm-evk` resolves to
`imx-boot-imx95-frdm-evk-sd.bin-flash_a55`, a 2,592,768-byte payload.

Build log:
`/srv/yocto/frdm-imx95-partner-v96/imx95-v96-thread-clean-0efbe51-r2.log`
(`1893eccc97163e5792c822b6022a1f526c6d00be42dc69d4fff699aec4cd4978`).

## Retained negative evidence

This gate closed three distinct failures instead of erasing them:

1. The clean baseline reached `otbr-iwxxx:do_compile` and failed because
   Scarthgap mDNSResponder 2200 does not declare
   `kDNSServiceErr_StaleData`. Log SHA-256:
   `46c32d4c4d12d373b2c92c6a9bc708e311be0b4fbd1547c7f53c0546093d20e4`.
2. The first corrected rerun stopped before BitBake because `path: .` resolved
   the partner layer from a stale `/work` cache snapshot, so KAS could not find
   the second connectivity patch. The base config now uses kas-container's
   explicit `/repo` Git-root mount. Log SHA-256:
   `9dc780bd4945633ea6fb747bfb0bf0506efba8729900a8f74301a9e64a28d93b`.
3. Once the real source was visible, BitBake correctly rejected
   `otbr-iwxxx_%.bbappend`: NXP's recipe is unversioned (`otbr-iwxxx.bb`), so
   the append is now unversioned too. Log SHA-256:
   `d85b558582ba05090e25e9aa88ab5488819d36c604efc75897c41381aa1f461b`.

These are reusable bring-up lessons: keep source and build-cache mounts
distinct, preserve dangling-append failures, and bind compatibility patches to
the exact vendor recipe naming convention.

## Evidence state

This closes the **built** state for the v96 IW612/Thread package gate. It does
not claim radio operation or Thread commissioning on the physical board; those
remain hardware-validation items.
