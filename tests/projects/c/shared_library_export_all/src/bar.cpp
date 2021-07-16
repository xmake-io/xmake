#include <stdio.h>

class bar
{
    bar() {}
    ~bar() {}
    void test() {}
};

void test(bar& b)
{
    printf("test\n");
}
