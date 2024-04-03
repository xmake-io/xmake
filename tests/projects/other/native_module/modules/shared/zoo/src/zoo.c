#include <xmi.h>

static int add(lua_State* lua) {
#if 0
    int a = lua_tointeger(lua, 1);
    int b = lua_tointeger(lua, 2);
    lua_pushinteger(lua, a + b);
#endif
    return 1;
}

static int sub(lua_State* lua) {
#if 0
    int a = lua_tointeger(lua, 1);
    int b = lua_tointeger(lua, 2);
    lua_pushinteger(lua, a - b);
#endif
    return 1;
}

int xmi_luaopen_foo(lua_State* lua) {
    static const luaL_Reg funcs[] = {
        {"add", add},
        {"sub", sub},
        {NULL, NULL}
    };
#if 0
    lua_newtable(lua);
    luaL_setfuncs(lua, funcs, 0);
#endif
    return 1;
}
