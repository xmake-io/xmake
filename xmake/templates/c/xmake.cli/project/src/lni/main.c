#include <xmake/xmake.h>

static tb_int_t lni_test_hello(lua_State* lua)
{
    lua_pushliteral(lua, "hello xmake!");
    return 1;
}
static tb_void_t lni_initalizer(xm_engine_ref_t engine, lua_State* lua)
{
    static luaL_Reg const lni_test_funcs[] =
    {
        {"hello", lni_test_hello}
    ,   {tb_null, tb_null}
    };
    xm_engine_register(engine, "test", lni_test_funcs);
}
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    tb_char_t* taskargv[] = {"lua", "-D", "lua.main", tb_null};
    return xm_engine_run("${TARGETNAME}", argc, argv, taskargv, lni_initalizer);
}
