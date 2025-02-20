#include "libfoo_api.h"
#include <stdio.h>

int main(int argc, char** argv) {
    printf("add(1, 2) = %d\n", kotlin_add(1, 2));
    return 0;
}
