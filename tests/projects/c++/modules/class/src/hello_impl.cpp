module hello;

#include <iostream>

using namespace std;

namespace hello {
    say::say(int data) : data_(data) {

    }

    void say::hello() {
        cout << "hello, say class: " << data_ << endl;
    }
}
