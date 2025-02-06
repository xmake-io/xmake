#include <xmake/xmake.h>

static lua_State* g_lua = tb_null;
static tb_void_t lni_initalizer(xm_engine_ref_t engine, lua_State* lua) {
    g_lua = lua;
}

static tb_char_t const* load_scriptfile(xm_engine_ref_t engine, tb_char_t const* filepath, tb_char_t const* arg1) {
    // reset result first
    lua_getglobal(g_lua, "_lni");
    lua_pushnil(g_lua);
    lua_setfield(g_lua, -2, "result");
    lua_pop(g_lua, 1);

    // load script and get result (string)
    tb_char_t* argv[] = {"xmake"};
    tb_char_t* taskargv[] = {"lua", "-D", (tb_char_t*)filepath, (tb_char_t*)arg1, tb_null};
    tb_char_t const* result = tb_null;
    if (xm_engine_main(engine, 1, argv, taskargv) == 0) {
        lua_getglobal(g_lua, "_lni");
        lua_getfield(g_lua, -1, "result");
        if (lua_isstring(g_lua, -1)) {
            result = tb_strdup(lua_tostring(g_lua, -1));
        }
        lua_pop(g_lua, 2);
    }
    return result;
}

static tb_void_t dump_targets(xm_engine_ref_t engine) {
    tb_trace_i("------------------------- targets -------------------------");
    tb_char_t const* result = load_scriptfile(engine, "assets/targets.lua", tb_null);
    if (result) {
        tb_trace_i("result: %s", result);
        tb_free(result);
    }
}

static tb_void_t dump_targetpath(xm_engine_ref_t engine) {
    tb_trace_i("------------------------- targetpath -------------------------");
    tb_char_t const* result = load_scriptfile(engine, "assets/targetpath.lua", "ide");
    if (result) {
        tb_trace_i("result: %s", result);
        tb_free(result);
    }
}

tb_int_t main(tb_int_t argc, tb_char_t** argv) {
    if (xm_init()) {
        xm_engine_ref_t engine = xm_engine_init("xmake", lni_initalizer);
        if (engine) {
            dump_targets(engine);
            dump_targetpath(engine);
            xm_engine_exit(engine);
        }
        xm_exit();
    }
    return 0;
}
