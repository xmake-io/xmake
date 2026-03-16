#include <stdio.h>

/* c must NOT inherit defines from a through b ({public = false}) */
#ifdef HAS_DS_A
#error "c should NOT inherit HAS_DS_A from shared a (public = false)"
#endif

/* c must NOT inherit includedirs from a through b ({public = false}) */
#if __has_include("ds_a.h")
#error "c should NOT inherit shared_static_dir includedir from shared a (public = false)"
#endif

extern int ds_get_b(void);

int main(int argc, char **argv) {
    printf("shared_static: %d\n", ds_get_b());
    return 0;
}
