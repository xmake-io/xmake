module foo;

template <>
struct foo<int> {
    constexpr const char* hello(void) const {
        return "hello int!";
    }
};