/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

inch
----

### Synopsis

    chtype inch(void);
    chtype winch(WINDOW *win);
    chtype mvinch(int y, int x);
    chtype mvwinch(WINDOW *win, int y, int x);

    int in_wch(cchar_t *wcval);
    int win_wch(WINDOW *win, cchar_t *wcval);
    int mvin_wch(int y, int x, cchar_t *wcval);
    int mvwin_wch(WINDOW *win, int y, int x, cchar_t *wcval);

### Description

   The inch() functions retrieve the character and attribute from
   the current or specified window position, in the form of a
   chtype. If a NULL window is specified, (chtype)ERR is returned.

   The in_wch() functions are the wide-character versions; instead
   of returning a chtype, they store a cchar_t at the address
   specified by wcval, and return OK or ERR. (No value is stored
   when ERR is returned.) Note that in PDCurses, chtype and cchar_t
   are the same.

### Portability
                             X/Open    BSD    SYS V
    inch                        Y       Y       Y
    winch                       Y       Y       Y
    mvinch                      Y       Y       Y
    mvwinch                     Y       Y       Y
    in_wch                      Y
    win_wch                     Y
    mvin_wch                    Y
    mvwin_wch                   Y

**man-end****************************************************************/

chtype winch(WINDOW *win)
{
    PDC_LOG(("winch() - called\n"));

    if (!win)
        return (chtype)ERR;

    return win->_y[win->_cury][win->_curx];
}

chtype inch(void)
{
    PDC_LOG(("inch() - called\n"));

    return winch(stdscr);
}

chtype mvinch(int y, int x)
{
    PDC_LOG(("mvinch() - called\n"));

    if (move(y, x) == ERR)
        return (chtype)ERR;

    return stdscr->_y[stdscr->_cury][stdscr->_curx];
}

chtype mvwinch(WINDOW *win, int y, int x)
{
    PDC_LOG(("mvwinch() - called\n"));

    if (wmove(win, y, x) == ERR)
        return (chtype)ERR;

    return win->_y[win->_cury][win->_curx];
}

#ifdef PDC_WIDE
int win_wch(WINDOW *win, cchar_t *wcval)
{
    PDC_LOG(("win_wch() - called\n"));

    if (!win || !wcval)
        return ERR;

    *wcval = win->_y[win->_cury][win->_curx];

    return OK;
}

int in_wch(cchar_t *wcval)
{
    PDC_LOG(("in_wch() - called\n"));

    return win_wch(stdscr, wcval);
}

int mvin_wch(int y, int x, cchar_t *wcval)
{
    PDC_LOG(("mvin_wch() - called\n"));

    if (!wcval || (move(y, x) == ERR))
        return ERR;

    *wcval = stdscr->_y[stdscr->_cury][stdscr->_curx];

    return OK;
}

int mvwin_wch(WINDOW *win, int y, int x, cchar_t *wcval)
{
    PDC_LOG(("mvwin_wch() - called\n"));

    if (!wcval || (wmove(win, y, x) == ERR))
        return ERR;

    *wcval = win->_y[win->_cury][win->_curx];

    return OK;
}
#endif
