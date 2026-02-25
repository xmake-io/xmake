#include <stdio.h>

/* c must NOT inherit defines from a through b ({public = false}) */
#ifdef HAS_HEADERONLY_A
#error "c should NOT inherit HAS_HEADERONLY_A from headeronly a (public = false)"
#endif

/* c must NOT inherit includedirs from a through b ({public = false}) */
#if __has_include("headeronly_a.h")
#error "c should NOT inherit headeronly_dir includedir from headeronly a (public = false)"
#endif

extern int headeronly_get_b(void);

int main(int argc, char **argv) {
    printf("headeronly: %d\n", headeronly_get_b());
    return 0;
}
