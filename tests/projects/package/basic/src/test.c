#include <stdio.h>
#include <pcre2.h>

int test()
{
    printf("hello world!\n");
    pcre2_compile(0, 0, 0, 0, 0, 0);
    return 0;
}

