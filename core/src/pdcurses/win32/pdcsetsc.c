/* Public Domain Curses */

#include "pdcwin.h"

/*man-start**************************************************************

pdcsetsc
--------

### Synopsis

    int PDC_set_blink(bool blinkon);
    void PDC_set_title(const char *title);

### Description

   PDC_set_blink() toggles whether the A_BLINK attribute sets an
   actual blink mode (TRUE), or sets the background color to high
   intensity (FALSE). The default is platform-dependent (FALSE in
   most cases). It returns OK if it could set the state to match
   the given parameter, ERR otherwise. Current platforms also
   adjust the value of COLORS according to this function -- 16 for
   FALSE, and 8 for TRUE.

   PDC_set_title() sets the title of the window in which the curses
   program is running. This function may not do anything on some
   platforms. (Currently it only works in Win32 and X11.)

### Portability
                             X/Open    BSD    SYS V
    PDC_set_blink               -       -       -
    PDC_set_title               -       -       -

**man-end****************************************************************/

int PDC_curs_set(int visibility)
{
    CONSOLE_CURSOR_INFO cci;
    int ret_vis;

    PDC_LOG(("PDC_curs_set() - called: visibility=%d\n", visibility));

    ret_vis = SP->visibility;

    if (GetConsoleCursorInfo(pdc_con_out, &cci) == FALSE)
        return ERR;

    switch(visibility)
    {
    case 0:             /* invisible */
        cci.bVisible = FALSE;
        break;
    case 2:             /* highly visible */
        cci.bVisible = TRUE;
        cci.dwSize = 95;
        break;
    default:            /* normal visibility */
        cci.bVisible = TRUE;
        cci.dwSize = SP->orig_cursor;
        break;
    }

    if (SetConsoleCursorInfo(pdc_con_out, &cci) == FALSE)
        return ERR;

    SP->visibility = visibility;
    return ret_vis;
}

void PDC_set_title(const char *title)
{
#ifdef PDC_WIDE
    wchar_t wtitle[512];
#endif
    PDC_LOG(("PDC_set_title() - called:<%s>\n", title));

#ifdef PDC_WIDE
    PDC_mbstowcs(wtitle, title, 511);
    SetConsoleTitleW(wtitle);
#else
    SetConsoleTitleA(title);
#endif
}

int PDC_set_blink(bool blinkon)
{
    if (pdc_color_started)
        COLORS = 16;

    return blinkon ? ERR : OK;
}
