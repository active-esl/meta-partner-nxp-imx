# FRDM-IMX95 Neutron llama.cpp experiment

Recipe support is opt-in and experimental. It does not change existing images,
kernel/firmware selection, boot arguments, CMA reservations or model provisioning.
The first hardware target is Qwen3-1.7B Q4_0; 4B/8B remain subsequent memory-budget
experiments, not evidence of current support.

## Source and integration

- Source: <https://github.com/open-ep/llama-neutron>, branch `neutron-npu`.
- Pin: `a74a3f86a8708517a139b548f91793d615dc4b0c`.
- Recipe: `llama-neutron`; machine: `imx95-frdm-evk` only.
- Optional packagegroup: `packagegroup-partner-nxp-imx95-neutron-experiment`.
- Requires the existing `imx-machine-learning` collection (NXP `meta-imx-ml`)
  and its `neutron` provider. Both recipes are gated through `BBFILES_DYNAMIC`.
- Installed tools: `llama-completion`, `llama-bench`, `neutron-pack` and, in the
  separate `llama-neutron-tests` package, `test-neutron-mm`.
- Models, packed caches and upstream server functionality are not included.
- Optional `neutron_3.1.1.bb` backports only the vendor runtime/firmware,
  pinned to `d0ff138390aeba2b6c5169d8f0ca13f6a6b8219a`.
  It is compatible only with `imx95-frdm-evk` and has `DEFAULT_PREFERENCE=-1`.
  It is skipped unless `FRDM_NEUTRON_EXPERIMENT = "1"`; negative default
  preference alone cannot override the partner layer's higher priority.
  Only the experiment KAS configuration enables it, with explicit FRDM
  enable and `PREFERRED_VERSION` overrides. Other boards and normal FRDM images keep their
  existing runtime selection. No vendor layer or kernel is repinned.
  The initial 6.12 runtime candidate passed API declarations but lacked private
  packing symbols at link time. The 3.1 family remains a build/hardware
  compatibility experiment with our existing 6.12 kernel, not a support claim.
  Recipe PV follows NXP; record the actual firmware version separately (the
  pinned source SBOM identifies neutron-software 3.1.2).
- Backend code is MIT. Its NOTICE documents NXP-derived MIT code, the mirrored
  kernel UAPI's Linux-syscall exception, and the separately supplied vendor
  headers/library. The `neutron` dependency retains its own vendor licence.

For an explicit experiment image, select the packagegroup in image/product
configuration using an FRDM-only override. Do not add it to recovery/mfgtool or
to the existing runtime packagegroup by default.

## Build proof before board execution

In the exact FRDM integration stack, with `meta-imx-ml` enabled:

```sh
kas-container build kas/lmp-v96-imx95-frdm-evk-neutron-experiment.yml
```

This component configuration inherits the existing pinned FRDM DEV stack and
targets only the experiment recipe/packagegroup, not a factory image. Its
inherited DEV signing settings are not production signing proof. On an already
configured matching build environment, use:

```sh
bitbake -p
bitbake -e llama-neutron
bitbake llama-neutron
```

That environment must explicitly set `FRDM_NEUTRON_EXPERIMENT:imx95-frdm-evk = "1"`
and `PREFERRED_VERSION_neutron:imx95-frdm-evk = "3.1.1"`, as the experiment KAS
configuration does. Without the enable gate, the existing vendor provider is
retained and cannot build this backend's required packing APIs.

Verify the resolved source revision, target architecture, `neutron` provider,
header/library staging, all four ELF executables and their shared dependencies,
licence manifests, package QA and test-package split. Confirm no image/package,
kernel/firmware or boot-policy change for unselected existing products. A recipe
draft or parse pass is not compilation or hardware proof.

## Hardware compatibility gate

Record running image identity, kernel, Neutron firmware and library versions,
device-node availability, `MemTotal`, `MemAvailable`, `CmaTotal`, `CmaFree`, and
current workload. Upstream tested `lf-6.18.20` with firmware `3.1.1`; older BSP
compatibility must be established, not assumed or silently fixed by an upgrade.

Run the matrix test in vendor-library mode and then direct mode, each as a fresh
process. Include relevant Qwen matrix widths. The supplied test uses a relative
RMS error threshold of 3%; retain actual errors and inspect model-level quality
too. Firmware-specific tiling workarounds need validation on our firmware.

## Model benchmark

Provide a checksummed, provenance-recorded Qwen3-1.7B **Q4_0** GGUF separately.
Pack once with `neutron-pack`; record cache size and packing duration. Other
quantisations do not establish NPU acceleration.

Compare CPU (`NEUTRON_DISABLE=1`), vendor-library transport, and direct transport
(`NEUTRON_DIRECT=1`) using the same model, context/batch sizes, six threads,
prompt token counts and output lengths. Use `NEUTRON_VERBOSE=1` to establish
actual offload and `NEUTRON_PROF=1` in a separate profiling run.

Measure cold loading separately from warm inference: input tokens/second,
time to first token, output tokens/second, end-to-end latency, memory and CMA
headroom, numerical/task quality and temperature. Useful workloads are long
fault logs or bounded diffs with short structured output. Retain exact commands
and artefact hashes under `test-reports/`, not in this procedure.

## Multi-region follow-on

Move to 4B only after correctness and memory evidence. Compare on-demand regions
against `NEUTRON_PREALLOC_REGIONS`; allocation fragmentation is a known upstream
risk. Repeated trials are bounded benchmark work, not a background monitor.

The FRDM has nominally 8 GB RAM; upstream quotes about 7 GB CMA for 8B. Account
for packed weights, region/scratch overhead, CPU tensors, KV cache and OS before
attempting it. Do not reserve 7 GB or change boot policy automatically. Keep
NPU-prefill/CPU-decode hybrid execution as a separately assessed development
proposal, not a supported runtime option.
