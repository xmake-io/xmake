#include <tbox/tbox.h>

int main()
{
    if (tb_init(tb_null, tb_null))
    {
        tb_trace_i("hello tbox!");
        tb_exit();
    }
}
