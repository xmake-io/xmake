// module;
#include <iostream>
module hello;

// import std.core;
using namespace std;

namespace hello {
    say::say(int data) : data_(data) {

    }

    void say::hello() {
        cout << "hello, say class: " << data_ << endl;
    }
}
