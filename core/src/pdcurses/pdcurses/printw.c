/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

printw
------

### Synopsis

    int printw(const char *fmt, ...);
    int wprintw(WINDOW *win, const char *fmt, ...);
    int mvprintw(int y, int x, const char *fmt, ...);
    int mvwprintw(WINDOW *win, int y, int x, const char *fmt,...);
    int vwprintw(WINDOW *win, const char *fmt, va_list varglist);
    int vw_printw(WINDOW *win, const char *fmt, va_list varglist);

### Description

   The printw() functions add a formatted string to the window at
   the current or specified cursor position. The format strings are
   the same as used in the standard C library's printf(). (printw()
   can be used as a drop-in replacement for printf().)

### Return Value

   All functions return the number of characters printed, or
   ERR on error.

### Portability
                             X/Open    BSD    SYS V
    printw                      Y       Y       Y
    wprintw                     Y       Y       Y
    mvprintw                    Y       Y       Y
    mvwprintw                   Y       Y       Y
    vwprintw                    Y       -      4.0
    vw_printw                   Y

**man-end****************************************************************/

#include <string.h>

int vwprintw(WINDOW *win, const char *fmt, va_list varglist)
{
    char printbuf[513];
    int len;

    PDC_LOG(("vwprintw() - called\n"));

#ifdef HAVE_VSNPRINTF
    len = vsnprintf(printbuf, 512, fmt, varglist);
#else
    len = vsprintf(printbuf, fmt, varglist);
#endif
    return (waddstr(win, printbuf) == ERR) ? ERR : len;
}

int printw(const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("printw() - called\n"));

    va_start(args, fmt);
    retval = vwprintw(stdscr, fmt, args);
    va_end(args);

    return retval;
}

int wprintw(WINDOW *win, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("wprintw() - called\n"));

    va_start(args, fmt);
    retval = vwprintw(win, fmt, args);
    va_end(args);

    return retval;
}

int mvprintw(int y, int x, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("mvprintw() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    va_start(args, fmt);
    retval = vwprintw(stdscr, fmt, args);
    va_end(args);

    return retval;
}

int mvwprintw(WINDOW *win, int y, int x, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("mvwprintw() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    va_start(args, fmt);
    retval = vwprintw(win, fmt, args);
    va_end(args);

    return retval;
}

int vw_printw(WINDOW *win, const char *fmt, va_list varglist)
{
    PDC_LOG(("vw_printw() - called\n"));

    return vwprintw(win, fmt, varglist);
}
