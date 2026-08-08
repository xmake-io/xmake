extern "C" {
#include <xmake/xmake.h>

extern tb_byte_t const _binary_luafiles_xmz_start[];
extern tb_byte_t const _binary_luafiles_xmz_end[];
}

static tb_int_t lni_test_hello(lua_State *lua) {
    lua_pushliteral(lua, "hello xmake!");
    return 1;
}

static tb_void_t lni_initalizer(xm_engine_ref_t engine, lua_State *lua) {
    static luaL_Reg const lni_test_funcs[] = { { "hello", lni_test_hello }, { tb_null, tb_null } };
    xm_engine_register(engine, "test", lni_test_funcs);
    xm_engine_add_embedfiles(engine, _binary_luafiles_xmz_start,
        (tb_size_t)(_binary_luafiles_xmz_end - _binary_luafiles_xmz_start));
}

tb_int_t main(tb_int_t argc, tb_char_t **argv) {
    tb_char_t *taskargv[] = { "lua", "-D", "lua.main", tb_null };
    return xm_engine_run("${TARGET_NAME}", argc, argv, taskargv, lni_initalizer);
}
