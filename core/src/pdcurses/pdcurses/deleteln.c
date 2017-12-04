/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

deleteln
--------

### Synopsis

    int deleteln(void);
    int wdeleteln(WINDOW *win);
    int insdelln(int n);
    int winsdelln(WINDOW *win, int n);
    int insertln(void);
    int winsertln(WINDOW *win);

    int mvdeleteln(int y, int x);
    int mvwdeleteln(WINDOW *win, int y, int x);
    int mvinsertln(int y, int x);
    int mvwinsertln(WINDOW *win, int y, int x);

### Description

   With the deleteln() and wdeleteln() functions, the line under
   the cursor in the window is deleted.  All lines below the
   current line are moved up one line.  The bottom line of the
   window is cleared.  The cursor position does not change.

   With the insertln() and winsertn() functions, a blank line is
   inserted above the current line and the bottom line is lost.

   mvdeleteln(), mvwdeleteln(), mvinsertln() and mvwinsertln()
   allow moving the cursor and inserting/deleting in one call.

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    deleteln                    Y       Y       Y
    wdeleteln                   Y       Y       Y
    mvdeleteln                  -       -       -
    mvwdeleteln                 -       -       -
    insdelln                    Y       -      4.0
    winsdelln                   Y       -      4.0
    insertln                    Y       Y       Y
    winsertln                   Y       Y       Y
    mvinsertln                  -       -       -
    mvwinsertln                 -       -       -

**man-end****************************************************************/

int wdeleteln(WINDOW *win)
{
    chtype blank, *temp, *ptr;
    int y;

    PDC_LOG(("wdeleteln() - called\n"));

    if (!win)
        return ERR;

    /* wrs (4/10/93) account for window background */

    blank = win->_bkgd;

    temp = win->_y[win->_cury];

    for (y = win->_cury; y < win->_bmarg; y++)
    {
        win->_y[y] = win->_y[y + 1];
        win->_firstch[y] = 0;
        win->_lastch[y] = win->_maxx - 1;
    }

    for (ptr = temp; (ptr - temp < win->_maxx); ptr++)
        *ptr = blank;           /* make a blank line */

    if (win->_cury <= win->_bmarg) 
    {
        win->_firstch[win->_bmarg] = 0;
        win->_lastch[win->_bmarg] = win->_maxx - 1;
        win->_y[win->_bmarg] = temp;
    }

    return OK;
}

int deleteln(void)
{
    PDC_LOG(("deleteln() - called\n"));

    return wdeleteln(stdscr);
}

int mvdeleteln(int y, int x)
{
    PDC_LOG(("mvdeleteln() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return wdeleteln(stdscr);
}

int mvwdeleteln(WINDOW *win, int y, int x)
{
    PDC_LOG(("mvwdeleteln() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return wdeleteln(win);
}

int winsdelln(WINDOW *win, int n)
{
    int i;

    PDC_LOG(("winsdelln() - called\n"));

    if (!win)
        return ERR;

    if (n > 0)
    {
        for (i = 0; i < n; i++)
            if (winsertln(win) == ERR)
                return ERR;
    }
    else if (n < 0)
    {
        n = -n;
        for (i = 0; i < n; i++)
            if (wdeleteln(win) == ERR)
                return ERR;
    }

    return OK;
}

int insdelln(int n)
{
    PDC_LOG(("insdelln() - called\n"));

    return winsdelln(stdscr, n);
}

int winsertln(WINDOW *win)
{
    chtype blank, *temp, *end;
    int y;

    PDC_LOG(("winsertln() - called\n"));

    if (!win)
        return ERR;

    /* wrs (4/10/93) account for window background */

    blank = win->_bkgd;

    temp = win->_y[win->_maxy - 1];

    for (y = win->_maxy - 1; y > win->_cury; y--)
    {
        win->_y[y] = win->_y[y - 1];
        win->_firstch[y] = 0;
        win->_lastch[y] = win->_maxx - 1;
    }

    win->_y[win->_cury] = temp;

    for (end = &temp[win->_maxx - 1]; temp <= end; temp++)
        *temp = blank;

    win->_firstch[win->_cury] = 0;
    win->_lastch[win->_cury] = win->_maxx - 1;

    return OK;
}

int insertln(void)
{
    PDC_LOG(("insertln() - called\n"));

    return winsertln(stdscr);
}

int mvinsertln(int y, int x)
{
    PDC_LOG(("mvinsertln() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return winsertln(stdscr);
}

int mvwinsertln(WINDOW *win, int y, int x)
{
    PDC_LOG(("mvwinsertln() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return winsertln(win);
}
