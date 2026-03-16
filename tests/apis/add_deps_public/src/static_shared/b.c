/* b is shared, a is static with {public = false}
 * b should inherit HAS_SD_A define and static_shared_dir includedir from a */
#include "sd_a.h"

#ifndef HAS_SD_A
#error "b should inherit HAS_SD_A from static a"
#endif

#if defined(_WIN32)
#define __export __declspec(dllexport)
#elif defined(__GNUC__) && ((__GNUC__ >= 4) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3))
#define __export __attribute__((visibility("default")))
#else
#define __export
#endif

extern int sd_get_a(void);

__export int sd_get_b(void) {
    return sd_get_a();
}
