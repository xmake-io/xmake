#include "prefix.h"

tb_int_t xm_os_access(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // check
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_char_t const* mode_str = luaL_checkstring(lua, 2);
    tb_check_return_val(path && mode_str, 0);

    // parse mode
    tb_size_t mode = 0;
    while (*mode_str) {
        switch (*mode_str) {
        case 'r': mode |= TB_FILE_MODE_RO; break;
        case 'w': mode |= TB_FILE_MODE_WO; break;
        case 'x': mode |= TB_FILE_MODE_EXEC; break;
        }
        mode_str++;
    }

    // check access
    lua_pushboolean(lua, tb_file_access(path, mode));
    return 1;
}
