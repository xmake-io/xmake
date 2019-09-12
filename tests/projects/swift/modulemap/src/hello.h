#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
    void say1(char const* s);
#ifdef __cplusplus
}
#endif
static inline void say2(char const* s) {
    printf("%s\n", s);
}


