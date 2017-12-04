/* Public Domain Curses */

#include <curspriv.h>

/* Deprecated functions. These should not be used, and will eventually 
   be removed. They're here solely for the benefit of applications that 
   linked to them in older versions of PDCurses. */

bool PDC_check_bios_key(void)
{
    return PDC_check_key();
}

int PDC_get_bios_key(void)
{
    return PDC_get_key();
}

bool PDC_get_ctrl_break(void)
{
    return !SP->raw_inp;
}

int PDC_set_ctrl_break(bool setting)
{
    return setting ? noraw() : raw();
}
