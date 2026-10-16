#include <stdio.h>

int main(void) {
#ifdef EXAMPLE_VERBOSE
    puts("includes: verbose");
#else
    puts("includes: quiet");
#endif
    return 0;
}
