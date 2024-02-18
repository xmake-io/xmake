#include <iostream>

import hello;
import say;
import foo;

int main() {
    hello::say_hello();
    say{}.hello<sizeof(say)>();
    std::cout << foo<int>{}.hello() << std::endl;
    return 0;
}
