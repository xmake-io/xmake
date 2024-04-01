/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "${TARGETNAME}/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * main
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv) {
    if (tb_init(tb_null, tb_null)) {
        tb_trace_i("hello tbox!");
        tb_trace_i("add(1 + 1) = %d", add(1, 1));
        tb_exit();
    }
    return 0;
}
