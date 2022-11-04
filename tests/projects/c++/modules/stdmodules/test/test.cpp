#include <stdio.h>

#ifdef _MSC_VER
import std.core;
#else
import std;
#endif

import my_module;

int main(int argc, char** argv) {
    printf("sum: %d\n", my_sum(1, 1));
}
