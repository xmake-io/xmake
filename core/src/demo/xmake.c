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
        // init machine
        xm_machine_ref_t machine = xm_machine_init();
        if (machine)
        {
            // done machine
            ok = xm_machine_main(machine, argc, argv);

            // exit machine
            xm_machine_exit(machine);
        }

        // exit xmake
        xm_exit();
    }

    // ok?
    return ok;
}
