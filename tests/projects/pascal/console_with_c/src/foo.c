#include <stdint.h>

extern int64_t fib(int64_t n) {
    return n > 1 ? fib(n - 1) + fib(n - 2) : 1;
}
