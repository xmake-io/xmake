#include <xmi.h>

int luaopen_cjson(lua_State* lua);

int luaopen(cjson, lua_State* lua) {
    return luaopen_cjson(lua);
}
