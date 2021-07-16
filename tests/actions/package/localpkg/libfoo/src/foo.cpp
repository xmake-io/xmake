#include "add.h"
#include "sub.h"
#include "foo.h"

int foo(int a, int b)
{
    return add(sub(a, b), sub(b, a));
}
