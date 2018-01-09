/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

instr
-----

### Synopsis

    int instr(char *str);
    int innstr(char *str, int n);
    int winstr(WINDOW *win, char *str);
    int winnstr(WINDOW *win, char *str, int n);
    int mvinstr(int y, int x, char *str);
    int mvinnstr(int y, int x, char *str, int n);
    int mvwinstr(WINDOW *win, int y, int x, char *str);
    int mvwinnstr(WINDOW *win, int y, int x, char *str, int n);

    int inwstr(wchar_t *wstr);
    int innwstr(wchar_t *wstr, int n);
    int winwstr(WINDOW *win, wchar_t *wstr);
    int winnwstr(WINDOW *win, wchar_t *wstr, int n);
    int mvinwstr(int y, int x, wchar_t *wstr);
    int mvinnwstr(int y, int x, wchar_t *wstr, int n);
    int mvwinwstr(WINDOW *win, int y, int x, wchar_t *wstr);
    int mvwinnwstr(WINDOW *win, int y, int x, wchar_t *wstr, int n);

### Description

   These functions take characters (or wide characters) from the
   current or specified position in the window, and return them as
   a string in str (or wstr). Attributes are ignored. The functions
   with n as the last argument return a string at most n characters
   long.

### Return Value

   Upon successful completion, innstr(), mvinnstr(), mvwinnstr()
   and winnstr() return the number of characters actually read into
   the string; instr(), mvinstr(), mvwinstr() and winstr() return
   OK. Otherwise, all these functions return ERR.

### Portability
                             X/Open    BSD    SYS V
    instr                       Y       -      4.0
    winstr                      Y       -      4.0
    mvinstr                     Y       -      4.0
    mvwinstr                    Y       -      4.0
    innstr                      Y       -      4.0
    winnstr                     Y       -      4.0
    mvinnstr                    Y       -      4.0
    mvwinnstr                   Y       -      4.0
    inwstr                      Y
    winwstr                     Y
    mvinwstr                    Y
    mvwinwstr                   Y
    innwstr                     Y
    winnwstr                    Y
    mvinnwstr                   Y
    mvwinnwstr                  Y

**man-end****************************************************************/

int winnstr(WINDOW *win, char *str, int n)
{
#ifdef PDC_WIDE
    wchar_t wstr[513];

    if (n < 0 || n > 512)
        n = 512;

    if (winnwstr(win, wstr, n) == ERR)
        return ERR;

    return (int)PDC_wcstombs(str, wstr, n);
#else
    chtype *src;
    int i;

    PDC_LOG(("winnstr() - called: n %d \n", n));

    if (!win || !str)
        return ERR;

    if (n < 0 || (win->_curx + n) > win->_maxx)
        n = win->_maxx - win->_curx;

    src = win->_y[win->_cury] + win->_curx;

    for (i = 0; i < n; i++)
        str[i] = (char)(src[i] & A_CHARTEXT);

    str[i] = '\0';

    return i;
#endif
}

int instr(char *str)
{
    PDC_LOG(("instr() - called: string=\"%s\"\n", str));

    return (ERR == winnstr(stdscr, str, stdscr->_maxx)) ? ERR : OK;
}

int winstr(WINDOW *win, char *str)
{
    PDC_LOG(("winstr() - called: \n"));

    return (ERR == winnstr(win, str, win->_maxx)) ? ERR : OK;
}

int mvinstr(int y, int x, char *str)
{
    PDC_LOG(("mvinstr() - called: y %d x %d \n", y, x));

    if (move(y, x) == ERR)
        return ERR;

    return (ERR == winnstr(stdscr, str, stdscr->_maxx)) ? ERR : OK;
}

int mvwinstr(WINDOW *win, int y, int x, char *str)
{
    PDC_LOG(("mvwinstr() - called: y %d x %d \n", y, x));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return (ERR == winnstr(win, str, win->_maxx)) ? ERR : OK;
}

int innstr(char *str, int n)
{
    PDC_LOG(("innstr() - called: n %d \n", n));

    return winnstr(stdscr, str, n);
}

int mvinnstr(int y, int x, char *str, int n)
{
    PDC_LOG(("mvinnstr() - called: y %d x %d n %d \n", y, x, n));

    if (move(y, x) == ERR)
        return ERR;

    return winnstr(stdscr, str, n);
}

int mvwinnstr(WINDOW *win, int y, int x, char *str, int n)
{
    PDC_LOG(("mvwinnstr() - called: y %d x %d n %d \n", y, x, n));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return winnstr(win, str, n);
}

#ifdef PDC_WIDE
int winnwstr(WINDOW *win, wchar_t *wstr, int n)
{
    chtype *src;
    int i;

    PDC_LOG(("winnstr() - called: n %d \n", n));

    if (!win || !wstr)
        return ERR;

    if (n < 0 || (win->_curx + n) > win->_maxx)
        n = win->_maxx - win->_curx;

    src = win->_y[win->_cury] + win->_curx;

    for (i = 0; i < n; i++)
        wstr[i] = src[i] & A_CHARTEXT;

    wstr[i] = L'\0';

    return i;
}

int inwstr(wchar_t *wstr)
{
    PDC_LOG(("inwstr() - called\n"));

    return (ERR == winnwstr(stdscr, wstr, stdscr->_maxx)) ? ERR : OK;
}

int winwstr(WINDOW *win, wchar_t *wstr)
{
    PDC_LOG(("winwstr() - called\n"));

    return (ERR == winnwstr(win, wstr, win->_maxx)) ? ERR : OK;
}

int mvinwstr(int y, int x, wchar_t *wstr)
{
    PDC_LOG(("mvinwstr() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return (ERR == winnwstr(stdscr, wstr, stdscr->_maxx)) ? ERR : OK;
}

int mvwinwstr(WINDOW *win, int y, int x, wchar_t *wstr)
{
    PDC_LOG(("mvwinstr() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return (ERR == winnwstr(win, wstr, win->_maxx)) ? ERR : OK;
}

int innwstr(wchar_t *wstr, int n)
{
    PDC_LOG(("innwstr() - called\n"));

    return winnwstr(stdscr, wstr, n);
}

int mvinnwstr(int y, int x, wchar_t *wstr, int n)
{
    PDC_LOG(("mvinnstr() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return winnwstr(stdscr, wstr, n);
}

int mvwinnwstr(WINDOW *win, int y, int x, wchar_t *wstr, int n)
{
    PDC_LOG(("mvwinnwstr() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return winnwstr(win, wstr, n);
}
#endif
