module foo;

import <cstdio>;

namespace foo {
    void say(const char *msg) {
        std::printf("%s", msg);
    }
}