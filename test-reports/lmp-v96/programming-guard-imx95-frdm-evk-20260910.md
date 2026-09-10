# FRDM-IMX95 guarded programming entry point

- Result: **PASS — static/operator safety-proof programming gate**
- Local board state: old target 2901 image booted into Linux; no i.MX95
  serial-download device was present, so no flash was attempted
- Guarded local bundle:
  `/data_drive/esl/frdm-imx95-programming/frdm-imx95-v96-product-r7-guarded`
- `PROGRAMMING-SHA256SUMS` SHA-256:
  `858c5d13a86e7927f432d195c168e9d51e8a96b794e7e923ba3e91674de4fd86`
- `program-imx95.sh` SHA-256:
  `7a049473fa5f0922310281cf407d080a0f505a228b79eae66aaa13f934905a4c`

The bundle assembler now installs a single operator entry point with explicit
`check`, `program`, and optional `verify` modes. Before invoking privileged
UUU, it:

1. verifies the SHA-256 of all six product/provenance artifacts plus the
   operator script and five extracted, programming-critical mfgtools payload
   files;
2. dry-parses the selected script using the bundled UUU binary;
3. requires exactly one MX95 SDPS device with NXP VID/PID `1fc9:015c` or
   `1fc9:015d`;
4. refuses a concurrent UUU process; and
5. records the live UUU output, exit status, and transcript byte count in a
   timestamped bundle-local log.

The MX95 IDs come directly from NXP's libuuu device table:
<https://github.com/nxp-imx/mfgtools/blob/master/libuuu/config.cpp>.

## Test evidence

- Bash and POSIX-shell syntax checks: pass
- ShellCheck on both programming helpers: pass with no findings
- `git diff --check`: pass
- Real r7 bundle assembly: pass
- Generated checksum manifest: 12 entries; all 12 pass
- No-device safety gate: pass; `check` exits 3 and gives the exact SW1/J3
  recovery action instead of waiting indefinitely or writing storage
- Corruption injection: appending one line to the generated `full_image.uuu`
  makes the wrapper fail its checksum gate before USB access
- Normal `program` mode selects only `full_image.uuu`; it does not invoke the
  slower read-back CRC
- `verify` remains a separate, explicit operation selecting
  `verify_image.uuu`

This closes the operator-entry-point and retained-transcript gap. It does not
claim hardware programming success: that gate remains open until the board is
put into serial-download mode, the guarded program operation exits zero, the
switches are restored to eMMC boot, and the new product produces boot/runtime
evidence.
