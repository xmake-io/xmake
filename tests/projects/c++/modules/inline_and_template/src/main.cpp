import hello;
import say;
import foo;

#include <iostream>

int main() {
    hello::say_hello();
    say{}.hello<sizeof(say)>();
    std::cout << foo<int>{}.hello() << std::endl;
    return 0;
}