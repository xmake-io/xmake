/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

move
----

### Synopsis

    int move(int y, int x);
    int wmove(WINDOW *win, int y, int x);

### Description

   The cursor associated with the window is moved to the given
   location.  This does not move the physical cursor of the
   terminal until refresh() is called.  The position specified is
   relative to the upper left corner of the window, which is (0,0).

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    move                        Y       Y       Y
    wmove                       Y       Y       Y

**man-end****************************************************************/

int move(int y, int x)
{
    PDC_LOG(("move() - called: y=%d x=%d\n", y, x));

    if (!stdscr || x < 0 || y < 0 || x >= stdscr->_maxx || y >= stdscr->_maxy)
        return ERR;

    stdscr->_curx = x;
    stdscr->_cury = y;

    return OK;
}

int wmove(WINDOW *win, int y, int x)
{
    PDC_LOG(("wmove() - called: y=%d x=%d\n", y, x));

    if (!win || x < 0 || y < 0 || x >= win->_maxx || y >= win->_maxy)
        return ERR;

    win->_curx = x;
    win->_cury = y;

    return OK;
}
