#include <xmake/xmake.h>

tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    tb_int_t ok = -1;
    if (xm_init())
    {
        xm_engine_ref_t engine = xm_engine_init();
        if (engine)
        {
            ok = xm_engine_main(engine, argc, argv);
            xm_engine_exit(engine);
        }
        xm_exit();
    }
    return ok;
}
