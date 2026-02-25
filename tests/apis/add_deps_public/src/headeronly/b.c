#include "headeronly_a.h"

#ifndef HAS_HEADERONLY_A
#error "b should inherit HAS_HEADERONLY_A from headeronly a"
#endif

int headeronly_get_b(void) {
    return headeronly_a_value();
}
