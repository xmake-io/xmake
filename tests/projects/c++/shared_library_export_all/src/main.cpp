#include "foo.h"
#include "bar.h"
#include <iostream>

int main(int argc, char **argv) {
    std::cout << "foo::add(1, 2) = " << foo::add(1, 2) << std::endl;
    std::cout << "bar::add(1, 2) = " << bar::add(1, 2) << std::endl;
    return 0;
}
