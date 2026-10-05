// SPDX-License-Identifier: MIT
// Compile/link capability check; never execute target code on the builder.
#include <cstddef>
#include <cstdint>
#include <neutron/NeutronDriver.h>
#include "neutron_pack.h"

// Volatile references retain linker relocations even in optimised builds.
#define REQUIRE_API(name) auto volatile check_##name = &name
REQUIRE_API(allocateBuffer);
REQUIRE_API(clean_cache);
REQUIRE_API(matmul);
REQUIRE_API(init_code_table);
REQUIRE_API(free_code_table);
REQUIRE_API(copy_code_table);
REQUIRE_API(find_min_int8);
REQUIRE_API(free_core_comp_result);
REQUIRE_API(extract_patterned_rows);
REQUIRE_API(fetch_unp_organize);
REQUIRE_API(weight_packer);
REQUIRE_API(tiling_solver);
REQUIRE_API(compress_weight_tensor);

int main() {
    return !check_allocateBuffer || !check_clean_cache || !check_matmul ||
           !check_init_code_table || !check_free_code_table ||
           !check_copy_code_table || !check_find_min_int8 ||
           !check_free_core_comp_result || !check_extract_patterned_rows ||
           !check_fetch_unp_organize || !check_weight_packer ||
           !check_tiling_solver || !check_compress_weight_tensor;
}
