#include <stdio.h>

extern char const* get_png_version();

int main(void) {
    printf("libpng version: %s\n", get_png_version());
    return 0;
}
