#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
    int i;
    for (i = 1; i < argc; ++i) {
        printf("arg[%d]=%s\n", i, argv[i]);
    }
    const char* env = getenv("XMAKE_TEST_ENV");
    printf("env=%s\n", env ? env : "");
    return 0;
}
