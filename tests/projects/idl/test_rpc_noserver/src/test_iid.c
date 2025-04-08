#include <Windows.h>
#include <example.h>
#include <stdio.h>

int main()
{
    MyInterface_v1_0_c_ifspec = (void*)1;
    printf("call ok\n");
    return 0;
}

void __RPC_FAR * __RPC_API midl_user_allocate(size_t cBytes) 
{ 
    return(malloc(cBytes)); 
}

void __RPC_API midl_user_free(void __RPC_FAR * p) 
{ 
    free(p); 
}
