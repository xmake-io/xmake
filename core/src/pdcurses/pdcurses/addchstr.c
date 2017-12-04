/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

addchstr
--------

### Synopsis

    int addchstr(const chtype *ch);
    int addchnstr(const chtype *ch, int n);
    int waddchstr(WINDOW *win, const chtype *ch);
    int waddchnstr(WINDOW *win, const chtype *ch, int n);
    int mvaddchstr(int y, int x, const chtype *ch);
    int mvaddchnstr(int y, int x, const chtype *ch, int n);
    int mvwaddchstr(WINDOW *, int y, int x, const chtype *ch);
    int mvwaddchnstr(WINDOW *, int y, int x, const chtype *ch, int n);

    int add_wchstr(const cchar_t *wch);
    int add_wchnstr(const cchar_t *wch, int n);
    int wadd_wchstr(WINDOW *win, const cchar_t *wch);
    int wadd_wchnstr(WINDOW *win, const cchar_t *wch, int n);
    int mvadd_wchstr(int y, int x, const cchar_t *wch);
    int mvadd_wchnstr(int y, int x, const cchar_t *wch, int n);
    int mvwadd_wchstr(WINDOW *win, int y, int x, const cchar_t *wch);
    int mvwadd_wchnstr(WINDOW *win, int y, int x, const cchar_t *wch,
                       int n);

### Description

   These routines write a chtype or cchar_t string directly into
   the window structure, starting at the current or specified
   position. The four routines with n as the last argument copy at
   most n elements, but no more than will fit on the line. If n =
   -1 then the whole string is copied, up to the maximum number
   that will fit on the line.

   The cursor position is not advanced. These routines do not check
   for newline or other special characters, nor does any line
   wrapping occur.

### Return Value

   All functions return OK or ERR.

### Portability
                             X/Open    BSD    SYS V
    addchstr                    Y       -      4.0
    waddchstr                   Y       -      4.0
    mvaddchstr                  Y       -      4.0
    mvwaddchstr                 Y       -      4.0
    addchnstr                   Y       -      4.0
    waddchnstr                  Y       -      4.0
    mvaddchnstr                 Y       -      4.0
    mvwaddchnstr                Y       -      4.0
    add_wchstr                  Y
    wadd_wchstr                 Y
    mvadd_wchstr                Y
    mvwadd_wchstr               Y
    add_wchnstr                 Y
    wadd_wchnstr                Y
    mvadd_wchnstr               Y
    mvwadd_wchnstr              Y

**man-end****************************************************************/

#include <string.h>

int waddchnstr(WINDOW *win, const chtype *ch, int n)
{
    int y, x, maxx, minx;
    chtype *ptr;

    PDC_LOG(("waddchnstr() - called: win=%p n=%d\n", win, n));

    if (!win || !ch || !n || n < -1)
        return ERR;

    x = win->_curx;
    y = win->_cury;
    ptr = &(win->_y[y][x]);

    if (n == -1 || n > win->_maxx - x)
        n = win->_maxx - x;

    minx = win->_firstch[y];
    maxx = win->_lastch[y];

    for (; n && *ch; n--, x++, ptr++, ch++)
    {
        if (*ptr != *ch)
        {
            if (x < minx || minx == _NO_CHANGE)
                minx = x;

            if (x > maxx)
                maxx = x;

            PDC_LOG(("y %d x %d minx %d maxx %d *ptr %x *ch"
                     " %x firstch: %d lastch: %d\n",
                     y, x, minx, maxx, *ptr, *ch, 
                     win->_firstch[y], win->_lastch[y]));

            *ptr = *ch;
        }
    }

    win->_firstch[y] = minx;
    win->_lastch[y] = maxx;

    return OK;
}

int addchstr(const chtype *ch)
{
    PDC_LOG(("addchstr() - called\n"));

    return waddchnstr(stdscr, ch, -1);
}

int addchnstr(const chtype *ch, int n)
{
    PDC_LOG(("addchnstr() - called\n"));

    return waddchnstr(stdscr, ch, n);
}

int waddchstr(WINDOW *win, const chtype *ch)
{
    PDC_LOG(("waddchstr() - called: win=%p\n", win));

    return waddchnstr(win, ch, -1);
}

int mvaddchstr(int y, int x, const chtype *ch)
{
    PDC_LOG(("mvaddchstr() - called: y %d x %d\n", y, x));

    if (move(y, x) == ERR)
        return ERR;

    return waddchnstr(stdscr, ch, -1);
}

int mvaddchnstr(int y, int x, const chtype *ch, int n)
{
    PDC_LOG(("mvaddchnstr() - called: y %d x %d n %d\n", y, x, n));

    if (move(y, x) == ERR)
        return ERR;

    return waddchnstr(stdscr, ch, n);
}

int mvwaddchstr(WINDOW *win, int y, int x, const chtype *ch)
{
    PDC_LOG(("mvwaddchstr() - called:\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return waddchnstr(win, ch, -1);
}

int mvwaddchnstr(WINDOW *win, int y, int x, const chtype *ch, int n)
{
    PDC_LOG(("mvwaddchnstr() - called: y %d x %d n %d \n", y, x, n));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return waddchnstr(win, ch, n);
}

#ifdef PDC_WIDE
int wadd_wchnstr(WINDOW *win, const cchar_t *wch, int n)
{
    PDC_LOG(("wadd_wchnstr() - called: win=%p n=%d\n", win, n));

    return waddchnstr(win, wch, n);
}

int add_wchstr(const cchar_t *wch)
{
    PDC_LOG(("add_wchstr() - called\n"));

    return wadd_wchnstr(stdscr, wch, -1);
}

int add_wchnstr(const cchar_t *wch, int n)
{
    PDC_LOG(("add_wchnstr() - called\n"));

    return wadd_wchnstr(stdscr, wch, n);
}

int wadd_wchstr(WINDOW *win, const cchar_t *wch)
{
    PDC_LOG(("wadd_wchstr() - called: win=%p\n", win));

    return wadd_wchnstr(win, wch, -1);
}

int mvadd_wchstr(int y, int x, const cchar_t *wch)
{
    PDC_LOG(("mvadd_wchstr() - called: y %d x %d\n", y, x));

    if (move(y, x) == ERR)
        return ERR;

    return wadd_wchnstr(stdscr, wch, -1);
}

int mvadd_wchnstr(int y, int x, const cchar_t *wch, int n)
{
    PDC_LOG(("mvadd_wchnstr() - called: y %d x %d n %d\n", y, x, n));

    if (move(y, x) == ERR)
        return ERR;

    return wadd_wchnstr(stdscr, wch, n);
}

int mvwadd_wchstr(WINDOW *win, int y, int x, const cchar_t *wch)
{
    PDC_LOG(("mvwadd_wchstr() - called:\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return wadd_wchnstr(win, wch, -1);
}

int mvwadd_wchnstr(WINDOW *win, int y, int x, const cchar_t *wch, int n)
{
    PDC_LOG(("mvwadd_wchnstr() - called: y %d x %d n %d \n", y, x, n));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return wadd_wchnstr(win, wch, n);
}
#endif
