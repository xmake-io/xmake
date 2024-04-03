#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>

static int add(lua_State* lua) {
    int a = lua_tointeger(lua, 1);
    int b = lua_tointeger(lua, 2);
    lua_pushinteger(lua, a + b);
    return 1;
}

static int sub(lua_State* lua) {
    int a = lua_tointeger(lua, 1);
    int b = lua_tointeger(lua, 2);
    lua_pushinteger(lua, a - b);
    return 1;
}

static const luaL_Reg g_funcs[] = {
    {"add", add},
    {"sub", sub},
    {NULL, NULL}
};

int luaopen_foo(lua_State* lua) {
    lua_newtable(lua);
    luaL_setfuncs(lua, g_funcs, 0);
    return 1;
}
