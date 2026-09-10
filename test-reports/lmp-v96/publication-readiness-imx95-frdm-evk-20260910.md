# FRDM-IMX95 v96 partner-layer publication readiness

- Result: **INCOMPLETE — local product build is reproducible, remote Factory
  inputs are not yet published and pinned**
- Partner development head: `1f392a9`
- Partner upstream/base: `foundriesio/meta-partner`, branch `nxp-imx`, head
  `176928480302c8e3b91348e07feecd3b2aa5dc83`
- Partner delta: 60 commits, 127 changed paths, 7,807 insertions and one
  deletion
- Product head used for the successful r7 build: local equivalent `dfb3168`
- BSP head used for the successful r7 build: local equivalent `625d066`
- Distro head used for the successful r7 build: local equivalent `39af55f`
- Curated local review branch: `review/imx95-frdm-nxp-6.12`; its six-commit
  implementation/evidence series ends at `e2cc5a6`, before this publication
  record is mirrored as the seventh commit
- Development/review Git tree: `ef44a092e73efc188ad9bf98994affa2acfe370c`

FoundriesFactory v96 explicitly relocated NXP BSP support from `meta-lmp` to
the `meta-partner` repository. The FRDM implementation follows that boundary:
coherent NXP platform, reference-machine, boot/update and manufacturing support
live in the partner layer; Dynamic Devices layers retain product policy and
customer-specific deltas.

## Proven local state

- The partner branch is based directly on `origin/nxp-imx`.
- The complete r7 Factory product image and static artifact verifier pass.
- The final r7 source trees on ai-tools are tree-equivalent to the reviewed
  local partner, BSP and distro fixes recorded in the build report.
- The product smoke KAS pins every upstream Foundries/NXP/OE component used by
  the v96 build.
- The 60-commit exploratory partner history has been regrouped locally into
  six review commits: coherent BSP, IW612/provider integration, pinned KAS
  gates, executable validation, retained evidence, and Foundries mfgtools.
- `git diff` is empty and the Git tree hash is identical between the green
  development head and the curated review head. Bash/POSIX syntax and
  ShellCheck pass for all four executable FRDM validation/programming helpers.

## Publication gaps

1. `DynamicDevices/meta-partner-nxp-imx` and
   `DynamicDevices/meta-partner-nxp-imx95` do not exist on GitHub.
2. The local development and curated review branches have no publishable
   Dynamic Devices remote; their only remote is Foundries' upstream repository.
3. `kas/lmp-imx95-frdm-evk-smoke.yml` deliberately uses sibling checkout paths
   for `meta-partner-nxp-imx`, `meta-dynamicdevices-bsp` and
   `meta-dynamicdevices-distro`. It is a valid local development gate, not an
   immutable Factory manifest.
4. The product branch is five commits ahead of
   `DynamicDevices/integration/imx95-frdm-screen-current`.
5. BSP commit `625d066` and distro commit `39af55f` are reviewed local heads but
   are not reachable from a tracked remote branch. The distro remote has an
   older content-equivalent KMS fix (`280f077`) on a different history; that is
   not proof that the exact r7 input is published.

## Required publication gate

Before triggering a production Foundries build:

1. agree the Dynamic Devices ownership model: a fork of
   `foundriesio/meta-partner` retaining the `nxp-imx` lineage is the default
   recommendation; upstream contribution can follow as a focused PR;
2. publish a reviewed FRDM branch and retain the exact partner commit SHA;
3. publish the exact BSP, distro and product integration heads;
4. replace the three development-only sibling paths with remote URLs and
   immutable commit SHAs in the production Factory manifest;
5. run KAS parse/component gates and a clean product build from those remote
   inputs; and
6. bind the resulting WIC/mfgtools bundle to that remote source lock before
   hardware acceptance.

No GitHub repository, fork, branch, PR or Factory build was created during this
audit. Those are external publication actions and must use the agreed
Dynamic Devices repository location. The existing green r7 artifacts remain
valid for the imminent bench flash and hardware validation.
