#include <xmake/xmake.h>

tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    tb_int_t ok = -1;
    if (xm_init())
    {
        xm_engine_ref_t engine = xm_engine_init(tb_null);
        if (engine)
        {
            tb_int_t   argc2 = argc + 2;
            tb_char_t* argv2[argc2 + 1];
            argv2[0]  = argv[0];
            argv2[1]  = "lua";
            argv2[2]  = "lua.main";
            if (argc > 1) tb_memcpy(argv2 + 3, argv + 1, (argc - 1) * sizeof(tb_char_t*));
            argv2[argc2] = tb_null;
            ok = xm_engine_main(engine, argc2, argv2);
            xm_engine_exit(engine);
        }
        xm_exit();
    }
    return ok;
}
