/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xmake/xmake.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * main
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    // init ok
    tb_int_t ok = -1;

    // init xmake
    if (xm_init())
    {
        // init engine
        xm_engine_ref_t engine = xm_engine_init(tb_null);
        if (engine)
        {
            // do engine main entry
            ok = xm_engine_main(engine, argc, argv);

            // exit engine
            xm_engine_exit(engine);
        }

        // exit xmake
        xm_exit();
    }

    // ok?
    return ok;
}
