/* b is static, a is shared with {public = false}
 * b should inherit HAS_DS_A define and shared_static_dir includedir from a */
#include "ds_a.h"

#ifndef HAS_DS_A
#error "b should inherit HAS_DS_A from shared a"
#endif

int ds_get_b(void) {
    return HAS_DS_A;
}
