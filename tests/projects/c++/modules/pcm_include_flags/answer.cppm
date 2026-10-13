module;
#include <local_value.h>
#include <system_value.h>

export module answer;

static_assert(FILE_VALUE == 42);

export int answer() {
    return LOCAL_VALUE + SYSTEM_VALUE;
}
