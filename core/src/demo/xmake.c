/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */ 
#include "xmake/xmake.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * main
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    // init xmake
    if (!xm_init()) return 0;

    // init machine
    xm_machine_ref_t machine = xm_machine_init();
    if (machine)
    {
        // done machine
        xm_machine_main(machine, argc, argv, "xmake_main.lua");

        // exit machine
        xm_machine_exit(machine);
    }

    // exit xmake
    xm_exit();

    // ok?
    return 0;
}
