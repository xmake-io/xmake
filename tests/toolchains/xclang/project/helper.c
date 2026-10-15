#include <stdio.h>
int helper(void) { char value[16]; return snprintf(value, sizeof(value), "%d", 42) == 2 ? 42 : -1; }
