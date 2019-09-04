#include "test.h"
  
int main(int argc, char** argv)
{
    test1();
#ifdef MACOSX
    test2();
    test3();
#endif
    test4();
    return 0;
}
