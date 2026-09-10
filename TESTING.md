# Device testing

This layer ships operator test plans that validate the FoundriesFactory LmP
update lifecycle end-to-end on the supported i.MX evaluation boards. The plans
are written to be run by an engineer at the bench — no automation or AI tooling
is required.

## Test plans

| Board | Plan |
|---|---|
| i.MX 8M Mini EVK (`imx8mm-lpddr4-evk`) | `test-plan/fio-test-plan-imx8mm-evk.md` |
| i.MX 8M Nano DDR4 EVK (`imx8mn-ddr4-evk`) | `test-plan/fio-test-plan-imx8mn-evk.md` |
| i.MX 8M Plus EVK (`imx8mp-lpddr4-evk`) | `test-plan/fio-test-plan-imx8mp-evk.md` |
| i.MX 8M Quad EVK (`imx8mq-evk`) | `test-plan/fio-test-plan-imx8mq-evk.md` |
| FRDM-IMX95 (`imx95-frdm-evk`) | `test-plan/frdm-imx95-hardware-validation.md` |

Each plan is a self-contained, step-by-step procedure. Pick the plan for the
board on your bench and follow it from top to bottom; every step lists the
command to run and the result to expect.

## What a run covers

A full run walks seven phases:

| Phase | Purpose |
|---|---|
| 0 | Lab setup — boot-mode switches, cabling, serial console with logging, first flash via `uuu`, IP discovery, verbose-boot enable |
| 1 | Happy-path OTA — the device pulls a new target and the update is confirmed |
| 2 | Failure injection — publish a deliberately broken target (panics early in boot) |
| 3 | Rollback — the broken target fails three boots and U-Boot rolls the device back |
| 4 | Cleanup / recovery — revert the broken change and update the device forward to a fixed target |
| 5 | Compose-app enablement — enable, deploy and verify the `shellhttpd` example app |
| 6 | Interface regression sweep — confirm no device interface broke during the run |

Phases 1–5 are operator-gated: a target only reaches the device when the
operator reveals it (see the plan's "Target reveal workflow" section).

## Phase 3 helper

`test-plan/phase3-rollback-monitor.sh` is an optional helper for Phase 3. Run it
on the host, pointed at the boards' logged serial consoles, just before the
broken target is revealed; it watches the panic/rollback sequence and reports
when each board has finished rolling back. Run `./phase3-rollback-monitor.sh -h`
for usage.

## Interface test

The Phase 6 sweep is an executable, device-side script, one per board:

- `test-plan/interface-test-imx8mm-evk.sh`
- `test-plan/interface-test-imx8mn-evk.sh`
- `test-plan/interface-test-imx8mp-evk.sh`
- `test-plan/interface-test-imx8mq-evk.sh`
- `test-plan/interface-test-imx95-frdm-evk.sh`

It runs ~22 grouped checks (system, networking, storage, OP-TEE, USB, Wi-Fi,
Bluetooth, audio, …) and prints a GitHub-flavored-markdown report with a
PASS / FAIL / INFO / SKIP verdict per check. Destructive and hardware-dependent
checks are skipped by default. Plan section 6.2 gives the exact invocation.

## Artifacts

For FRDM-IMX95, validate a completed deploy directory before programming:

```sh
test-plan/verify-imx95-build-artifacts.sh \
  build/tmp/deploy/images/imx95-frdm-evk --product --mfgtool
```

Omit `--product` for the standalone partner-layer Factory gate. Product mode
also requires Weston, Waydroid, both Zigbee RCP recipes and the NXP OTBR
package group in the image manifest. Add `--mfgtool` when the deploy directory
also contains the manufacturing archive. This checks the i.MX95 recovery
payloads, complete Foundries WIC write, both production boot slots, separate
optional read-back script and UUU dry-run parsing. The verifier prints SHA-256
fingerprints for the publishable WIC, production boot container, U-Boot FIT,
manifest and manufacturing archive when present.

The Factory image and mfgtools archive come from separate builds. Assemble a
single, matched programming directory without overwriting an earlier pack:

```sh
test-plan/prepare-imx95-programming-bundle.sh \
  build/tmp/deploy/images/imx95-frdm-evk \
  mfgtool-files-imx95-frdm-evk.tar.gz \
  uuu-imx95-product
```

The helper refuses recovery payloads in the production slots, checks the full
Foundries WIC/dual-slot script and separate aligned verification script, runs
both through bundled UUU's dry parser, writes `PROGRAMMING-SHA256SUMS`, and
publishes the output atomically. It also installs `program-imx95.sh`, which
checks every production and recovery input, requires exactly one NXP MX95
BootROM device (`1fc9:015c` or `1fc9:015d`), refuses a concurrent UUU process,
and retains a timestamped UUU transcript. Use `check`, `program`, or the
separate optional `verify` mode; normal programming never performs the slower
read-back CRC.

Completed-run evidence is committed under **`test-reports/<lmp-release>/`** (e.g.
`test-reports/lmp-v96/`), keyed by LmP release line — the machine name is in each
filename, so artifacts sit flat under the release folder. `test-reports/README.md`
indexes every release run with its verdict. Each run produces:

- `interface-test-results-<machine>-<datetime>.md` — the full Phase 6 output
- `interface-test-summary-<machine>-<datetime>.md` — a one-row-per-interface roll-up
- a test-record file summarising the Phase 1–6 outcome (see plan section 6.4)

Serial-console logs (`serial-*.log`) are kept locally as evidence but are
git-ignored — large and per-run.

## Scope

These plans target the EVKs above on a FoundriesFactory whose CI builds
`lmp-factory-image`. Recovery procedures for misfires (re-flash via `uuu`,
breaking into U-Boot, signature failures) are in each plan's "Recovery" section.
