#include <stdio.h>

#ifdef _WIN32
__declspec(dllexport) 
#endif
void foo() {
    printf("foo called\n");
}

