// module;
#include <iostream>
module hello;
import mod;

void inner() {
    std::cout << "hello world! data: "
              << mod::foo() << std::endl;
}

namespace hello {
    int data__;
    void say_hello() { ::inner(); }

    say::say(int data) : data_{data} {

    }

    void say::hello() {
        hello::data__ = data_;
        ::inner();
    }
}
