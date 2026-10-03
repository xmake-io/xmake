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
    const char* here = getenv("XMAKE_TEST_HERE");
    printf("here=%s\n", here ? here : "");
    const char* prefix = getenv("XMAKE_TEST_PREFIX");
    printf("prefix=%s\n", prefix ? prefix : "");
    return 0;
}
