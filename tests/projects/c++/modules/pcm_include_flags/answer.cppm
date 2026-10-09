module;
#include <local_value.h>
#include <system_value.h>

export module answer;

export int answer() {
    return LOCAL_VALUE + SYSTEM_VALUE;
}
