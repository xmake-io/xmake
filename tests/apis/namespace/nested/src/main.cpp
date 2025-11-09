#include "foo.h"
#include "bar.h"
#include <iostream>

int main(int argc, char **argv) {
    std::cout << "add(1, 2) = " << add(1, 2) << std::endl;
    std::cout << "sub(2, 1) = " << sub(2, 1) << std::endl;
    return 0;
}
