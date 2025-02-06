#include <xmake/xmake.h>

static tb_bool_t load_scriptfile(xm_engine_ref_t engine, tb_char_t const* filepath, tb_char_t const* arg1) {
    tb_char_t* argv[] = {"xmake"};
    tb_char_t* taskargv[] = {"lua", "-D", (tb_char_t*)filepath, (tb_char_t*)arg1, tb_null};
    return xm_engine_main(engine, 1, argv, taskargv) == 0;
}

static tb_void_t dump_targets(xm_engine_ref_t engine) {
    tb_trace_i("------------------------- targets -------------------------");
    load_scriptfile(engine, "assets/targets.lua", tb_null);
}

static tb_void_t dump_targetpath(xm_engine_ref_t engine) {
    tb_trace_i("------------------------- targetpath -------------------------");
    load_scriptfile(engine, "assets/targetpath.lua", "ide");
}

tb_int_t main(tb_int_t argc, tb_char_t** argv) {
    if (xm_init()) {
        xm_engine_ref_t engine = xm_engine_init("xmake", tb_null);
        if (engine) {
            dump_targets(engine);
            dump_targetpath(engine);
            xm_engine_exit(engine);
        }
        xm_exit();
    }
    return 0;
}
