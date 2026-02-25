/* b is static, a is static with {public = false}
 * b should inherit HAS_SS_A define and static_static_dir includedir from a */
#include "ss_a.h"

#ifndef HAS_SS_A
#error "b should inherit HAS_SS_A from static a"
#endif

int ss_get_b(void) {
    return HAS_SS_A;
}
