module;
#include <iostream>
using namespace std;

module hello;

namespace hello {
    say::say(int data) : data_(data) {

    }
    void say::hello() {
        cout << "hello, say class: " << data_ << endl;
    }
}
