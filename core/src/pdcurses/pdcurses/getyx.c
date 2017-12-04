/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

getyx
-----

### Synopsis

    void getyx(WINDOW *win, int y, int x);
    void getparyx(WINDOW *win, int y, int x);
    void getbegyx(WINDOW *win, int y, int x);
    void getmaxyx(WINDOW *win, int y, int x);

    void getsyx(int y, int x);
    int setsyx(int y, int x);

    int getbegy(WINDOW *win);
    int getbegx(WINDOW *win);
    int getcury(WINDOW *win);
    int getcurx(WINDOW *win);
    int getpary(WINDOW *win);
    int getparx(WINDOW *win);
    int getmaxy(WINDOW *win);
    int getmaxx(WINDOW *win);

### Description

   The getyx() macro (defined in curses.h -- the prototypes here
   are merely illustrative) puts the current cursor position of the
   specified window into y and x. getbegyx() and getmaxyx() return
   the starting coordinates and size of the specified window,
   respectively. getparyx() returns the starting coordinates of the
   parent's window, if the specified window is a subwindow;
   otherwise it sets y and x to -1. These are all macros.

   getsyx() gets the coordinates of the virtual screen cursor, and
   stores them in y and x. If leaveok() is TRUE, it returns -1, -1.
   If lines have been removed with ripoffline(), then getsyx()
   includes these lines in its count; so, the returned y and x
   values should only be used with setsyx().

   setsyx() sets the virtual screen cursor to the y, x coordinates.
   If y, x are -1, -1, leaveok() is set TRUE.

   getsyx() and setsyx() are meant to be used by a library routine
   that manipulates curses windows without altering the position of
   the cursor. Note that getsyx() is defined only as a macro.

   getbegy(), getbegx(), getcurx(), getcury(), getmaxy(),
   getmaxx(), getpary(), and getparx() return the appropriate
   coordinate or size values, or ERR in the case of a NULL window.

### Portability
                             X/Open    BSD    SYS V
    getyx                       Y       Y       Y
    getparyx                    -       -      4.0
    getbegyx                    -       -      3.0
    getmaxyx                    -       -      3.0
    getsyx                      -       -      3.0
    setsyx                      -       -      3.0
    getbegy                     -       -       -
    getbegx                     -       -       -
    getcury                     -       -       -
    getcurx                     -       -       -
    getpary                     -       -       -
    getparx                     -       -       -
    getmaxy                     -       -       -
    getmaxx                     -       -       -

**man-end****************************************************************/

int getbegy(WINDOW *win)
{
    PDC_LOG(("getbegy() - called\n"));

    return win ? win->_begy : ERR;
}

int getbegx(WINDOW *win)
{
    PDC_LOG(("getbegx() - called\n"));

    return win ? win->_begx : ERR;
}

int getcury(WINDOW *win)
{
    PDC_LOG(("getcury() - called\n"));

    return win ? win->_cury : ERR;
}

int getcurx(WINDOW *win)
{
    PDC_LOG(("getcurx() - called\n"));

    return win ? win->_curx : ERR;
}

int getpary(WINDOW *win)
{
    PDC_LOG(("getpary() - called\n"));

    return win ? win->_pary : ERR;
}

int getparx(WINDOW *win)
{
    PDC_LOG(("getparx() - called\n"));

    return win ? win->_parx : ERR;
}

int getmaxy(WINDOW *win)
{
    PDC_LOG(("getmaxy() - called\n"));

    return win ? win->_maxy : ERR;
}

int getmaxx(WINDOW *win)
{
    PDC_LOG(("getmaxx() - called\n"));

    return win ? win->_maxx : ERR;
}

int setsyx(int y, int x)
{
    PDC_LOG(("setsyx() - called\n"));

    if(y == -1 && x == -1)
    {
        curscr->_leaveit = TRUE;
        return OK;
    }
    else
    {
        curscr->_leaveit = FALSE;
        return wmove(curscr, y, x);
    }
}
