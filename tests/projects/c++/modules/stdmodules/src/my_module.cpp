module my_module;

#ifdef MSVC_MODULES
import std.core;
#else
import std;
#endif

auto my_sum(size_t a, size_t b) -> size_t { return a + b; }
