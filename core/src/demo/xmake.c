/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */ 
#include "xmake/xmake.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * main
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    // init tbox
#if 0
    if (!tb_init(tb_null, (tb_byte_t*)malloc(300 * 1024 * 1024), 300 * 1024 * 1024)) return 0;
#else
    if (!tb_init(tb_null, tb_null, 0)) return 0;
#endif

    // init xmake
    if (!xm_init()) return 0;


    // exit xmake
    xm_exit();

    // exit tbox
    tb_exit();

    // ok?
    return 0;
}
