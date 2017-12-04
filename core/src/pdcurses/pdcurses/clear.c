/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

clear
-----

### Synopsis

    int clear(void);
    int wclear(WINDOW *win);
    int erase(void);
    int werase(WINDOW *win);
    int clrtobot(void);
    int wclrtobot(WINDOW *win);
    int clrtoeol(void);
    int wclrtoeol(WINDOW *win);

### Description

   erase() and werase() copy blanks (i.e. the background chtype) to
   every cell of the window.

   clear() and wclear() are similar to erase() and werase(), but
   they also call clearok() to ensure that the the window is
   cleared on the next wrefresh().

   clrtobot() and wclrtobot() clear the window from the current
   cursor position to the end of the window.

   clrtoeol() and wclrtoeol() clear the window from the current
   cursor position to the end of the current line.

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    clear                       Y       Y       Y
    wclear                      Y       Y       Y
    erase                       Y       Y       Y
    werase                      Y       Y       Y
    clrtobot                    Y       Y       Y
    wclrtobot                   Y       Y       Y
    clrtoeol                    Y       Y       Y
    wclrtoeol                   Y       Y       Y

**man-end****************************************************************/

int wclrtoeol(WINDOW *win)
{
    int x, y, minx;
    chtype blank, *ptr;

    PDC_LOG(("wclrtoeol() - called: Row: %d Col: %d\n",
             win->_cury, win->_curx));

    if (!win)
        return ERR;

    y = win->_cury;
    x = win->_curx;

    /* wrs (4/10/93) account for window background */

    blank = win->_bkgd;

    for (minx = x, ptr = &win->_y[y][x]; minx < win->_maxx; minx++, ptr++)
        *ptr = blank;

    if (x < win->_firstch[y] || win->_firstch[y] == _NO_CHANGE)
        win->_firstch[y] = x;

    win->_lastch[y] = win->_maxx - 1;

    PDC_sync(win);
    return OK;
}

int clrtoeol(void)
{
    PDC_LOG(("clrtoeol() - called\n"));

    return wclrtoeol(stdscr);
}

int wclrtobot(WINDOW *win)
{
    int savey, savex;

    PDC_LOG(("wclrtobot() - called\n"));

    if (!win)
        return ERR;

    savey = win->_cury;
    savex = win->_curx;

    /* should this involve scrolling region somehow ? */

    if (win->_cury + 1 < win->_maxy)
    {
        win->_curx = 0;
        win->_cury++;
        for (; win->_maxy > win->_cury; win->_cury++)
            wclrtoeol(win);
        win->_cury = savey;
        win->_curx = savex;
    }
    wclrtoeol(win);

    PDC_sync(win);
    return OK;
}

int clrtobot(void)
{
    PDC_LOG(("clrtobot() - called\n"));

    return wclrtobot(stdscr);
}

int werase(WINDOW *win)
{
    PDC_LOG(("werase() - called\n"));

    if (wmove(win, 0, 0) == ERR)
        return ERR;

    return wclrtobot(win);
}

int erase(void)
{
    PDC_LOG(("erase() - called\n"));

    return werase(stdscr);
}

int wclear(WINDOW *win)
{
    PDC_LOG(("wclear() - called\n"));

    if (!win)
        return ERR;

    win->_clear = TRUE;
    return werase(win);
}

int clear(void)
{
    PDC_LOG(("clear() - called\n"));

    return wclear(stdscr);
}
