module foo;

import bar;

namespace foo {
int hello() {
    return bar::hello();
}
} // namespace foo
