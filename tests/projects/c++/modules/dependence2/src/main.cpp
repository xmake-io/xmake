#include <stdio.h>

import foo;

int main() {
    printf("add(1, 2): %d\n", foo::add(1, 2));
    printf("sub(1, 2): %d\n", foo::sub(1, 2));
    return 0;
}

