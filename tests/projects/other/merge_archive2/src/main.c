#include <stdio.h>

int add(int a, int b);
int sub(int a, int b);
int mul(int a, int b);
int subdir_add(int a, int b);
int subdir_sub(int a, int b);

int main(int argc, char** argv)
{
    printf("%d\n", add(1, 1));
    printf("%d\n", sub(1, 1));
    printf("%d\n", mul(1, 1));
    printf("%d\n", subdir_add(1, 1));
    printf("%d\n", subdir_sub(1, 1));
    return 0;
}
