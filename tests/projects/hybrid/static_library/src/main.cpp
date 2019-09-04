#include "test.h"
  
int main(int argc, char** argv)
{
    test1();
    test2();
#ifdef MACOSX
    test3();
    test4();
#endif
    return 0;
}
