#include <stdio.h>

extern int test(int a, int b);
int main(int argc, char** argv)
{
    printf("1 + 1 = %d\n", test(1, 1));
    return 0;
}
