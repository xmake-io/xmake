#include <stdio.h>

#ifndef EXAMPLE_TOOLCHAIN
#error The addon toolchain must supply EXAMPLE_TOOLCHAIN.
#endif

int main(void) {
    printf("addon toolchain: %d\n", EXAMPLE_TOOLCHAIN);
    return 0;
}
