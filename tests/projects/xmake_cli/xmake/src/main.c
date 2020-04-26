#include <xmake/xmake.h>

tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
    return xm_engine_run("xmake", argc, argv, tb_null, tb_null);
}
