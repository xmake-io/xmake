/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

beep
----

### Synopsis

    int beep(void);
    int flash(void);

### Description

   beep() sounds the audible bell on the terminal, if possible;
   if not, it calls flash().

   flash() "flashes" the screen, by inverting the foreground and
   background of every cell, pausing, and then restoring the
   original attributes.

### Return Value

   These functions return OK.

### Portability
                             X/Open    BSD    SYS V
    beep                        Y       Y       Y
    flash                       Y       Y       Y

**man-end****************************************************************/

int beep(void)
{
    PDC_LOG(("beep() - called\n"));

    if (SP->audible)
        PDC_beep();
    else
        flash();

    return OK;
}

int flash(void)
{
    int z, y, x;

    PDC_LOG(("flash() - called\n"));

    /* Reverse each cell; wait; restore the screen */

    for (z = 0; z < 2; z++)
    {
        for (y = 0; y < LINES; y++)
            for (x = 0; x < COLS; x++)
                curscr->_y[y][x] ^= A_REVERSE;

        wrefresh(curscr);

        if (!z)
            napms(50);
    }

    return OK;
}
