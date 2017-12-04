/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

delch
-----

### Synopsis

    int delch(void);
    int wdelch(WINDOW *win);
    int mvdelch(int y, int x);
    int mvwdelch(WINDOW *win, int y, int x);

### Description

   The character under the cursor in the window is deleted.  All
   characters to the right on the same line are moved to the left
   one position and the last character on the line is filled with
   a blank.  The cursor position does not change (after moving to
   y, x if coordinates are specified).

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    delch                       Y       Y       Y
    wdelch                      Y       Y       Y
    mvdelch                     Y       Y       Y
    mvwdelch                    Y       Y       Y

**man-end****************************************************************/

#include <string.h>

int wdelch(WINDOW *win)
{
    int y, x, maxx;
    chtype *temp1;

    PDC_LOG(("wdelch() - called\n"));

    if (!win)
        return ERR;

    y = win->_cury;
    x = win->_curx;
    maxx = win->_maxx - 1;
    temp1 = &win->_y[y][x];

    memmove(temp1, temp1 + 1, (maxx - x) * sizeof(chtype));

    /* wrs (4/10/93) account for window background */

    win->_y[y][maxx] = win->_bkgd;

    win->_lastch[y] = maxx;

    if ((win->_firstch[y] == _NO_CHANGE) || (win->_firstch[y] > x))
        win->_firstch[y] = x;

    PDC_sync(win);

    return OK;
}

int delch(void)
{
    PDC_LOG(("delch() - called\n"));

    return wdelch(stdscr);
}

int mvdelch(int y, int x)
{
    PDC_LOG(("mvdelch() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return wdelch(stdscr);
}

int mvwdelch(WINDOW *win, int y, int x)
{
    PDC_LOG(("mvwdelch() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return wdelch(win);
}
