#include <stdio.h>
#include <pcre2.h>

int test();

int main(int argc, char** argv)
{
    printf("hello world!\n");
    pcre2_compile(0, 0, 0, 0, 0, 0);
    test();
    return 0;
}
