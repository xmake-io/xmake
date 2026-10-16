#include <stdio.h>

#ifndef EXAMPLE_MESSAGE
#error The addon rule must supply EXAMPLE_MESSAGE.
#endif

int main(void) {
    printf("%s (%d tags)\n", EXAMPLE_MESSAGE, EXAMPLE_TAG_COUNT);
    return 0;
}
