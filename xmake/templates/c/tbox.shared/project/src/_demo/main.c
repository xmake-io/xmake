/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "${TARGETNAME}/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * main
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    // init tbox
    if (!tb_init(tb_null, tb_null)) return -1;

    // trace
    tb_trace_i("hello tbox!");

    // test
    tb_trace_i("add(1 + 1) = %d", add(1, 1));

    // exit tbox
    tb_exit();
    return 0;
}
