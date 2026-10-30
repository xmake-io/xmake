import <foo/bar.h>;
import <baz/bar.h>;
import <root.h>;
import <cstdlib>;
import "local.h";

int main() {
    return foo_answer() == 42 && baz_answer() == 7 && root_answer() == 3 && local_answer() == 1
        && std::abs(-42) == 42 ? 0 : 1;
}
