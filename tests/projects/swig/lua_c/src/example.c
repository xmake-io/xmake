#include <stdio.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

extern int luaopen_example(lua_State* L); // declare the wrapped module

int main(int argc,char* argv[])
{
    lua_State *L;
    if (argc<2)
    {
        printf("%s: <filename.lua>\n",argv[0]);
        return 0;
    }
    L=lua_open();
    luaopen_base(L);	// load basic libs (eg. print)
    luaopen_example(L);	// load the wrappered module
    if (luaL_loadfile(L,argv[1])==0) // load and run the file
        lua_pcall(L,0,0,0);
    else
        printf("unable to load %s\n",argv[1]);
    lua_close(L);
    return 0;
}
