#include <stdio.h>

/* c must NOT inherit defines from a through b ({public = false}) */
#ifdef HAS_SD_A
#error "c should NOT inherit HAS_SD_A from static a (public = false)"
#endif

/* c must NOT inherit includedirs from a through b ({public = false}) */
#if __has_include("sd_a.h")
#error "c should NOT inherit static_shared_dir includedir from static a (public = false)"
#endif

extern int sd_get_b(void);

int main(int argc, char **argv) {
    printf("static_shared: %d\n", sd_get_b());
    return 0;
}
