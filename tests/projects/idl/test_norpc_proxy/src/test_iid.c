#include <lockowner.h>
#include <stdio.h>

int main()
{
    IID g = IID_ILockOwner;
    printf("GUID: %x-%x-%x-%llx", g.Data1, g.Data2, g.Data3, *(unsigned long long*)g.Data4);
    return 0;
}
