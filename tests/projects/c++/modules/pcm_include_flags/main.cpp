#include <local_value.h>
#include <system_value.h>

import answer;

int main() {
    return answer() == LOCAL_VALUE + SYSTEM_VALUE ? 0 : 1;
}
