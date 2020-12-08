#include <stdio.h>

int add(int a, int b);
int main(int argc, char **argv) {
    int result = add(42, 1337);
    printf("%d\n", result);
    return 0;
}
