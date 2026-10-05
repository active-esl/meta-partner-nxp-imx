# FRDM-IMX95 llama-neutron initial recipe validation

Date: 2026-10-05. Status: component compilation/package QA passed;
runtime-selection isolation corrected; hardware unverified.

Worktree: `meta-partner-nxp-imx95-neutron-experiment`, branch
`feature/frdm-imx95-llama-neutron`, based on partner BSP commit `965d3fa`.
Upstream backend pinned to `a74a3f86a8708517a139b548f91793d615dc4b0c`.

## Evidence

- Compared recipe licence MD5s against the pinned upstream LICENSE and NOTICE.
- Reviewed pinned CMake targets: all four selected executables exist; tests are
  built but never executed on the cross-compilation host. Library SONAME major
  versions are zero and are listed as private recipe libraries.
- `bitbake -b <absolute llama-neutron_git.bb path> -e` completed successfully
  in an isolated temporary build directory with the local FRDM layer stack.
  Resolved `PN=llama-neutron`, the exact source revision, FRDM-only machine
  restriction, `neutron` dependency, Neutron-enabled CMake configuration and
  `llama-neutron-tests` split containing `/usr/bin/test-neutron-mm`.
- The optional packagegroup's targeted metadata parse also completed; its
  runtime dependencies select only `llama-neutron` and `llama-neutron-tests`.
  Machine architecture is assigned before inheriting `packagegroup` to avoid
  accidental `allarch` classification.
- Whitespace checks on the new recipe and procedure produced no diagnostics.
- Existing image/packagegroup selections, source manifests, signing policy,
  kernel/firmware and CMA settings are unchanged.

## Integration limitation

The full `bitbake -p` attempt failed on absent factory signing-key files in the
isolated environment. This occurred across existing kernel/bootloader recipes;
it is not a successful integration parse or proof that the new dependency graph
builds. No signing bypass or placeholder keys were introduced.

The initial local layer configuration also omitted its declared DD BSP layer
dependency; that omission was corrected only in the temporary validation stack.
The shared build configuration was not edited.

## Outstanding evidence

- Exact-stack full parse and resolved dependency graph.
- Real AArch64 compilation, packaging, licence and shared-library QA.
- Compatibility of the selected vendor library and kernel UAPI with this fork;
  the upstream tested firmware/kernel combination differs from our older stack.
- Board correctness, actual offload, model quality, memory budget and performance.

Procedure: `test-plan/frdm-imx95-neutron-llm-experiment.md`.

## Component build preparation

- Added `kas/lmp-v96-imx95-frdm-evk-neutron-experiment.yml`, inheriting the
  existing exact-pinned FRDM DEV stack and selecting only the new recipe and
  optional packagegroup. Initial YAML assertions verified the targets and
  absence of repository-pin or local signing-policy overrides.
- Confirmed `ai-tools` is the QEMU guest, has about 685 GiB free disk and
  36 GiB available memory, and had no active compiler/BitBake workload at intake.
- Staged the candidate in `/srv/yocto/frdm-imx95-neutron-experiment/repo`;
  independent work/build/download/sstate directories avoid modifying existing
  product build trees. Existing caches are mounted read-only as mirrors.
- Builder-local overlay limits BitBake and compiler concurrency to four.
- Corrected launch configuration to use `ghcr.io/siemens/kas/kas:4.7` explicitly
  and to keep concatenated KAS configurations in the same repository. Earlier
  launch attempts exited before BitBake; they are not build evidence.
- Corrected launch fetched and checked out the configured exact layer SHAs,
  applied the existing connectivity compatibility patches, and reached
  BitBake cache loading. Compilation/package success remains unverified.

The existing parent DEV configuration has its own unsigned development policy;
using it is not production signing proof and does not change product policy.

The first real BitBake invocation parsed 3744 recipes but exited on four
pre-existing Waydroid-related appends without providers in the partner-only
stack: `libgbinder`, `libglibutil`, `python3-gbinder_git` and `waydroid`. The
experiment KAS configuration now excludes only these exact append paths for
this component-only build. It does not disable dangling-append checking or
alter product configurations. This correction is not compilation proof.

The subsequent stack parse completed without errors but target resolution
reported `Nothing PROVIDES 'llama-neutron'`. The partner layer's existing
`BBFILES_DYNAMIC` entry matched only `.bbappend` files. Added the corresponding
`.bb` pattern for the same `imx-machine-learning` collection; without it, direct
single-recipe metadata checks cannot prove recipe discovery by the layer.

After adding that discovery pattern, the corrected component launch parsed 3746
recipes with zero parse errors, resolved both targets and entered task execution
on `ai-tools`. Sstate reported 201 of 222 objects available from the read-only
mirror (90% match). The experiment packagegroup completed packaging tasks and
the selected vendor `neutron` dependency reached sysroot staging. This is
verified startup/dependency integration, not yet a successful backend compile
or package QA result.

Recipe content SHA-256 matched between local and builder copies:
`481dde816a46fc2bab5affd4dcb70c571164dc0e8d46eef31c089cc4f82adc19`.

## Real compilation outcome

The component build stopped at `llama-neutron:do_compile`. Compiler diagnostics
show the selected vendor header does not declare `allocateBuffer`, `clean_cache`
or `matmul`. The `neutron` provider is pinned to NXP revision
`1c32f65741c827aabf2ab3edb03227fd25c7cfca`, branch `lf-6.6.52_2.2.0`.
These are actual backend API requirements, not missing include paths; the
header is staged and its older graph-level API was inspected independently.

Reduction source: the single 13,359-byte `log.do_compile.5812` for the failed
task. Extracted the first six compiler `error:` diagnostics in source order
(maximum twelve admitted), suppressing progress/warnings and terminal wrapper
errors. Raw logs remain owned by the build tree. The failed run attempted 672
tasks; 644 did not need to be rerun and one task failed.

Added a compile-only header capability preflight to fail before compiling the
full backend when these APIs are absent. This does not upgrade any dependency
or silently build a CPU-only substitute. Its source changes supersede the
recipe hash quoted for the failed run; a successful new build is not claimed.

Next requires a deliberate choice: qualify an isolated newer vendor runtime
and its kernel/firmware compatibility, or investigate a backport to the
existing stack. No BSP, firmware or product manifest upgrade was performed.

## Fail-fast check verification

Executed the new `neutron-api-check.cpp` against the failed build's exact
AArch64 compiler and staged vendor sysroot, using KAS 4.7 with the build tree
mounted read-only, networking disabled, and `-fsyntax-only` input from stdin.
It exited 1 and reported precisely the three absent declarations:
`allocateBuffer`, `clean_cache`, and `matmul`. No object file, runtime change,
dependency upgrade or board operation was performed. This verifies the check's
negative case against the actual selected provider, not compatibility with a
newer provider or the complete BitBake configure hook.

Further runtime qualification remains a proposal awaiting Alex's explicit
direction; the automatic goal continuation does not authorise that expansion.

## FRDM-only runtime qualification authorised

Alex subsequently instructed: "lets do this for the FRDM board only please".
Implementation is confined to the optional FRDM component build; no normal
image selection, product manifest, kernel, CMA setting or deployment changed.

The first matched 6.12 runtime candidate, named `neutron_2.2.1.bb` and pinned
to `a7d5f17a9210c45aef2bbc9dc09d637f41fd3a7c`, passed the declaration preflight
but failed linking `neutron-pack`. In `log.do_compile.1811` (31,289 bytes), the
first failed action was `bin/neutron-pack`, with undefined references including
`init_code_table`, `compress_weight_tensor`, `weight_packer` and `tiling_solver`.
The vendor library's exported symbol table confirmed that the three matrix APIs
were present but these private packing symbols were absent. This supersedes the
earlier inference that declarations alone made the 6.12 runtime sufficient.

Replaced the failed candidate in the working change with NXP's `neutron_3.1.1.bb`
source pin `d0ff138390aeba2b6c5169d8f0ca13f6a6b8219a`, retaining
`COMPATIBLE_MACHINE=^imx95-frdm-evk$` and `DEFAULT_PREFERENCE=-1`. Only the
experiment KAS configuration has the FRDM-specific preferred-version override.
The pin follows the vendor recipe; its source SBOM labels neutron-software 3.1.2,
so actual firmware identification is still required before hardware claims.
The failed builder-side candidate was moved outside recipe discovery and kept
as evidence; no existing product recipe was deleted.

Strengthened the preflight to compile **and link** references to all thirteen
required matrix/packing APIs, without executing the target binary. This check
passed against the selected 3.1 provider during the real component build, which
then entered `llama-neutron:do_compile`.

Verified the candidate metadata pin, negative default preference and exact
machine restriction. A bounded `bitbake -b <candidate> -c listtasks` test with
`MACHINE=imx8mm-lpddr4-evk` exited 1 because the candidate was incompatible;
no recipe task was run. Direct `-e` inspection alone is not a negative gating
test because it requests skipped recipe metadata too.

Logs are retained under the isolated builder work directory as
`runtime221-build-r1.log` and `runtime311-build-r1.log`. Reduced task transitions
and exact error diagnostics were admitted; raw logs were not copied into chat.

## Successful component build and packaging

The 3.1 candidate compiled and installed all selected tools. Initial package QA
identified two unversioned runtime implementation libraries incorrectly placed
in `-dev`, followed by a missing development symlink after narrowing the split.
Inspected every installed shared-library symlink chain, then explicitly assigned
the CLI implementation ELF files to runtime and all five versioned development
symlinks to `-dev`. No QA checks were disabled.

Final builder log `runtime311-build-r3.log` records `do_package_qa: Succeeded`
and "Attempted 682 tasks of which 674 didn't need to be rerun and all succeeded".
Confirmed all four selected executables are AArch64 ELF files. Runtime package
metadata requires `neutron (>= 3.1.1)`; the tests package requires the matching
`llama-neutron` package and contains `/usr/bin/test-neutron-mm`.

Produced IPKs under the isolated builder's `build/tmp/deploy/ipk/cortexa55`:

- `llama-neutron_0.0+git0+a74a3f86a8-r0_cortexa55.ipk`, about 3.1 MiB,
  SHA-256 `eeb080054b14534ae6cf3c7ece4176d13483fc31b9a9ed50d59b5e21a194d0e5`.
- `llama-neutron-tests_0.0+git0+a74a3f86a8-r0_cortexa55.ipk`, about 11 KiB,
  SHA-256 `75241a902f1e63a4b28857a38f37964640570b9ad5c34bfc2ab9e259330fcbee`.
- `neutron_3.1.1-r0_cortexa55.ipk`, about 58 KiB,
  SHA-256 `c5fb3b063fcfa1401e67eb1a6f3ae4ea232112a88f5fbb5c51bd88ab2a24c449`.

No board was accessed or modified. Hardware matrix correctness, firmware
identity, actual offload, memory budget and CPU/NPU model benchmarks remain
outstanding. A component package build is not a test-image or deployed BSP pass.

## Runtime-selection isolation correction

The first default-selection regression check cleared the experiment's preferred
version but still resolved `neutron 3.1.1`. The partner layer priority is 9 and
the upstream `imx-machine-learning` layer priority is 8. BitBake's
`sortPriorities` groups by layer priority before default preference, so
`DEFAULT_PREFERENCE=-1` alone did not protect normal FRDM selections. Earlier
claims based solely on that preference are superseded by this finding.

Added a parse-time skip unless `FRDM_NEUTRON_EXPERIMENT = "1"`. Only the
experiment KAS sets the enable variable, with an exact FRDM machine override;
the existing machine restriction still excludes other boards even when enabled.
No shared configuration sets this variable.

The corrected disabled-path check used the exact experiment stack with a
post-read configuration setting the enable variable to `0` and clearing the
preferred version. `bitbake -e neutron` exited 0 and selected `PV="1.0.0"`,
`SRCREV="1c32f65741c827aabf2ab3edb03227fd25c7cfca"`, the original provider.
Evidence: builder `work/default-runtime-selection.log`. The gate also skips
when the enable variable is absent, because only the exact value `1` enables it.

Output reduction for the isolation checks admits only anchored resolved
`PN/PV/SRCREV/DEFAULT_PREFERENCE/FRDM_NEUTRON_EXPERIMENT` assignments, parse/task
summaries and `ERROR` diagnostics from each single run. Raw evidence remains in
the isolated builder work directory, not in chat.

The enabled-path recheck resolved `FRDM_NEUTRON_EXPERIMENT="1"`, `PV="3.1.1"`
and the exact candidate source pin. Parsing completed with zero errors, and
the component build reported all 682 tasks succeeded (all reused). This
confirms the isolation gate does not disturb the previously compiled/package-QA
validated experiment. Evidence: builder `work/runtime-isolation-enabled.log`.

## Foundries development build preparation

Alex requested a Foundries build on the standard development branch and
explicitly authorised the online FRDM board's OTA. The current manifest head
is `9c09762d6e48a9f9081e5394b1cd6f6660e6329b` on
`main-imx95-frdm-devel`; it pins the partner BSP to
`cdaa191b80a104547c20a51cb4a7aad5d9099733`. Fast-forwarded this experiment
worktree to that exact baseline, preserving the existing display/Waydroid fixes
rather than rolling them back to the earlier component-build baseline.

Added a conditional FRDM-only packagegroup selection to the factory image
append. It is enabled only by the explicit experiment variable; mfgtool and
recovery images receive no new package selection. The Foundries manifest
candidate enables the runtime using exact FRDM overrides. No kernel, CMA,
boot-policy or other-board selections are changed relative to the current
factory baseline.

All four existing partner source-contract scripts passed after integration;
whitespace checks passed. This preparation is not a Foundries build or OTA pass.
Publication and hardware state remain to be verified.
