# FRDM-IMX95 Zigbee SDK consumer gate

- Result: **PASS**
- Machine: `imx95-frdm-evk`
- Distro: `lmp`, Foundries LmP v96 / Scarthgap
- Partner source: local `a8e74ce`, staged ai-tools `78e35732`
- NXP connectivity source: `14a32aa7467f58257e3bb93a5c0fa443c70ae1ae`
- Target: `zigbee-rcp-apps`
- Final run: 2026-09-10 06:07:30–06:07:50 UTC
- Tasks: 719 attempted; 713 reused; all succeeded
- Final log: `ai-tools:/srv/yocto/frdm-imx95-partner-v96/imx95-v96-zigbee-current-a8e74ce-r3.log`,
  10,452 bytes, SHA-256
  `c81fe663e76d62679b5e7e0912167e10d110373ed62a909c040b14a82fc63a2a`

## Compatibility findings

NXP's `zigbee-rcp-sdk` and `zigbee-rcp-apps` recipes both use
`S = "${UNPACKDIR}"`. LmP v96's BitBake 2.8.1 does not define `UNPACKDIR`, so
the partner layer scopes both recipes to `S = "${WORKDIR}"` on
`imx95-frdm-evk`. The SDK archive and the applications' file-based `SRC_URI`
both place their source directly there.

The first consumer run proved the SDK correction: `zigbee-rcp-sdk:do_unpack`
and `do_prepare_recipe_sysroot` passed, then the applications recipe exposed
the same issue. Retained failure log:

- `ai-tools:/srv/yocto/frdm-imx95-partner-v96/imx95-v96-zigbee-current-15e0525-r1.log`
- 12,507 bytes
- SHA-256 `d8adcac28d2c137e3aff4254f0de7a024c2221ba5326c721bc73b78724696943`

The second run built both recipes and their packages but exposed an invalid
upstream `LIC_FILES_CHKSUM`: the applications recipe is `LICENSE = "CLOSED"`
and its file-based source does not contain the declared `LICENSE`. The
FRDM-scoped append clears that checksum, which is not required for a CLOSED
recipe. The final run has only the six pre-existing paired warnings that NXP
prefers unavailable `nativesdk-qemu` 8.2.2.imx while LmP v96 provides 8.2.7.

## Produced package evidence

- `zigbee-rcp-apps_1.0-r0_cortexa55.ipk`: 2,408 bytes,
  SHA-256 `f2c16b2b3cbf70dae2f38b64909f698c5c19ecad959358473c1aada501a69c6b`
- `zigbee-rcp-apps-dbg_1.0-r0_cortexa55.ipk`: 4,118 bytes,
  SHA-256 `a0261c67634b4cb2318955e19fba2a55a903dce7642f2b9eb54e85d251d20d49`

## Gate conclusion

This is a real consumer gate, not metadata-only evidence: the SDK compiled and
populated its sysroot, and the applications compiled, installed, passed package
QA and emitted IPKs against it. The integrated Factory image may now be retried
with this dependency chain proven independently.
