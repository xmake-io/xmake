#include <string>
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif
extern "C" EXPORT int shared_value() { return static_cast<int>(std::string("xclang").size()); }
