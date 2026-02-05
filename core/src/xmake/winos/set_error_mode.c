#include "prefix.h"

tb_int_t xm_winos_set_error_mode(lua_State *lua) {
    tb_size_t mode = (tb_size_t)luaL_checkinteger(lua, 1);
    lua_pushinteger(lua, (tb_int_t)SetErrorMode((UINT)mode));
    return 1;
}
