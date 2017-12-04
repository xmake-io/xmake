/* Public Domain Curses */

#include "pdcwin.h"

/* get the cursor size/shape */

int PDC_get_cursor_mode(void)
{
    CONSOLE_CURSOR_INFO ci;
    
    PDC_LOG(("PDC_get_cursor_mode() - called\n"));

    GetConsoleCursorInfo(pdc_con_out, &ci);

    return ci.dwSize;
}

/* return number of screen rows */

int PDC_get_rows(void)
{
    CONSOLE_SCREEN_BUFFER_INFO scr;

    PDC_LOG(("PDC_get_rows() - called\n"));

    GetConsoleScreenBufferInfo(pdc_con_out, &scr);

    return scr.srWindow.Bottom - scr.srWindow.Top + 1;
}

/* return number of buffer rows */

int PDC_get_buffer_rows(void)
{
    CONSOLE_SCREEN_BUFFER_INFO scr;

    PDC_LOG(("PDC_get_buffer_rows() - called\n"));

    GetConsoleScreenBufferInfo(pdc_con_out, &scr);

    return scr.dwSize.Y;
}

/* return width of screen/viewport */

int PDC_get_columns(void)
{
    CONSOLE_SCREEN_BUFFER_INFO scr;

    PDC_LOG(("PDC_get_columns() - called\n"));

    GetConsoleScreenBufferInfo(pdc_con_out, &scr);

    return scr.srWindow.Right - scr.srWindow.Left + 1;
}
