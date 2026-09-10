# FRDM-IMX95 v96 partner-layer publication readiness

- Result: **INCOMPLETE — partner layer published; remaining Factory inputs
  still require immutable remote publication**
- Active ESL fork: `https://github.com/active-esl/meta-partner-nxp-imx`
- GitHub relationship: public fork of `foundriesio/meta-partner`
- Upstream/base: branch `nxp-imx`, head
  `176928480302c8e3b91348e07feecd3b2aa5dc83`
- Curated implementation head before this metadata record:
  `review/imx95-frdm-nxp-6.12` at
  `4af6181c7ab4ffbc0e319c516d83d29a35d5f3f6`
- Development implementation head before its matching metadata record:
  `feature/imx95-frdm-nxp-6.12` at
  `155f11fd62a7470206d4d48a770f25834f6a7257`
- Development/review Git tree:
  `367f7ce63a097404e619026ac7f6d4aec59ba27a`
- Development delta: 67 commits, 130 changed paths, 7,984 insertions and one
  deletion

FoundriesFactory v96 explicitly relocated NXP BSP support from `meta-lmp` to
the `meta-partner` repository. The FRDM implementation follows that boundary:
coherent NXP platform, reference-machine, boot/update and manufacturing
support live in the partner layer; Dynamic Devices layers retain product
policy and customer-specific deltas.

## Proven state

- GitHub identifies the Active ESL repository as a fork whose parent and
  source are both `foundriesio/meta-partner`; the upstream relationship is
  preserved rather than represented by an unrelated source repository.
- Both local branches track their exact Active ESL remote branches, and GitHub
  returned the full commit IDs recorded above.
- Gitleaks scanned the 12-commit curated delta before its first push and found
  no leaks. The branch contains no Codex/Cursor co-author trailers.
- The green r8 product build at partner head `3fbc71c` attempted all 8,423
  tasks successfully and passed the independent product-artifact verifier
  34/34. It proves the FRDM EEPROM node and System Manager/SCMI RTC
  configuration; see
  `product-build-pass-imx95-frdm-evk-20260910T100352Z.md`.
- The two later curated commits only scope optional connectivity appends out of
  the deliberately smaller mfgtools graph. The corrected graph parsed 3,681
  recipes with six masked files and zero errors at `a9dd237`.

## Remaining publication gaps

1. The exact BSP head `625d066`, distro head `39af55f` and product integration
   head `dfb3168` are reviewed local inputs but are not all reachable from
   tracked remote branches.
2. `kas/lmp-imx95-frdm-evk-smoke.yml` still uses sibling checkout paths for
   the partner, BSP and distro components. It is a valid local-development
   gate, not an immutable Factory manifest.
3. The current green product WIC was built from local tree-equivalent inputs,
   not by cloning every component from its final remote source lock.
4. The matching `a9dd237` mfgtools archive, atomic programming bundle and
   hardware evidence are still in progress.

## Required publication gate

Before triggering the production Foundries build:

1. publish the exact BSP, distro and product integration heads;
2. replace development-only sibling paths with remote URLs and immutable
   commit SHAs in the production Factory manifest;
3. run KAS parse/component gates and a clean product build from those remote
   inputs;
4. reproduce the now-green matched WIC and mfgtools archive from that remote
   source lock; and
5. complete programming, boot, rollback and requirement-by-requirement board
   acceptance.

No upstream Foundries PR or production Factory build has been created. Those
are later gates; the Active ESL partner fork and its two working branches are
now published and ready to be consumed by the product source lock. Local r8
product plus r15 recovery artifacts pass the combined 48-check gate; this is
strong local build evidence, not yet a remotely reproducible Factory source
lock or hardware acceptance result.
