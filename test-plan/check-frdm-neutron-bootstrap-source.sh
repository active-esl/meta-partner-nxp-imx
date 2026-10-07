#!/usr/bin/env bash
# Native mocked source fixture only: no target execution, driver, or DMA.
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
recipe="$root/dynamic-layers/imx-machine-learning/recipes-libraries/llama-neutron/llama-neutron_git.bb"
files="${recipe%/*}/files"
grep -Fqx 'COMPATIBLE_MACHINE = "^imx95-frdm-evk$"' "$recipe"
grep -Fqx 'SRCREV = "a74a3f86a8708517a139b548f91793d615dc4b0c"' "$recipe"
grep -Fqx 'inherit cmake features_check' "$recipe"
grep -Fqx 'REQUIRED_DISTRO_FEATURES += "llama-neutron"' "$recipe"
for optional in \
    "$root/dynamic-layers/imx-machine-learning/recipes-libraries/neutron/neutron_3.1.1.bb" \
    "$root/dynamic-layers/imx-machine-learning/recipes-core/packagegroups/packagegroup-partner-nxp-imx95-neutron-experiment.bb"; do
    grep -Fqx 'COMPATIBLE_MACHINE = "^imx95-frdm-evk$"' "$optional"
    grep -Fqx 'REQUIRED_DISTRO_FEATURES += "llama-neutron"' "$optional"
done
if grep -Rq 'FRDM_NEUTRON_EXPERIMENT' \
    "$root/dynamic-layers/imx-machine-learning" \
    "$root/recipes-samples/images/lmp-factory-image.bbappend" \
    "$root/kas/lmp-v96-imx95-frdm-evk-neutron-experiment.yml"; then
    echo "FAIL: legacy variable still controls optional NPU software" >&2
    exit 1
fi
grep -Fq 'file://0001-neutron-release-tracked-bootstrap-mapping.patch' "$recipe"
grep -Fq 'file://mapping-tail-guard.h' "$recipe"
grep -Fq 'install -m 0644 ${WORKDIR}/mapping-tail-guard.h ${S}/ggml/src/ggml-cpu/neutron/' "$recipe"
test "$(sha256sum "$files/mapping-tail-guard.h" | cut -d' ' -f1)" = c38d1b6ac6326a66b5ebc572ced93872c97f6dd2163f70cf507cc3ec25d5526a
grep -Fq 'if (releaseBuffer(p) != ENONE)' "$files/0001-neutron-release-tracked-bootstrap-mapping.patch"
grep -Fq 'bootstrap_finish_release(tracked, p);' "$files/0001-neutron-release-tracked-bootstrap-mapping.patch"
# This patch must not import the scratch-only two-region configuration/counters.
if grep -Eq 'NEUTRON_PREALLOC_REGIONS|completed_jobs|GUARD_FAIL third/invalid region' "$files/0001-neutron-release-tracked-bootstrap-mapping.patch"; then
    echo "FAIL: scratch-only region restrictions leaked into recipe patch" >&2
    exit 1
fi
command -v g++ >/dev/null
work=$(mktemp -d "${TMPDIR:-/tmp}/frdm-neutron-source-fixtures.XXXXXX")
g++ -std=c++17 -O2 -Wall -Wextra -I"$files" "$root/test-plan/frdm-neutron-mapping-fixtures.cpp" -o "$work/mapping-fixtures"
timeout -k 2 10 "$work/mapping-fixtures" >"$work/fixtures.log" 2>&1
grep -Fx 'MAPPING_FIXTURES_PASS 30 checks; mock unmap exact-owned-tail only' "$work/fixtures.log"
printf 'FRDM_NEUTRON_SOURCE_GATE_PASS\nFixture evidence retained: %s\n' "$work"
