#include <stdio.h>

/* c must NOT inherit defines from a through b ({public = false}) */
#ifdef HAS_SS_A
#error "c should NOT inherit HAS_SS_A from static a (public = false)"
#endif

/* c must NOT inherit includedirs from a through b ({public = false}) */
#if __has_include("ss_a.h")
#error "c should NOT inherit static_static_dir includedir from static a (public = false)"
#endif

extern int ss_get_b(void);

int main(int argc, char **argv) {
    printf("static_static: %d\n", ss_get_b());
    return 0;
}
