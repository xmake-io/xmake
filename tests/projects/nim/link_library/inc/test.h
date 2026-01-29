
#ifndef TEST_H
#define TEST_H

#ifdef TEST_STATIC
    #define TEST_MSG "Hello from Static Lib!"
#else
    #define TEST_MSG "Hello from Shared Lib!"
#endif

#endif
