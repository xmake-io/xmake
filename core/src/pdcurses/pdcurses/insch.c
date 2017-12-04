/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

insch
-----

### Synopsis

    int insch(chtype ch);
    int winsch(WINDOW *win, chtype ch);
    int mvinsch(int y, int x, chtype ch);
    int mvwinsch(WINDOW *win, int y, int x, chtype ch);

    int insrawch(chtype ch);
    int winsrawch(WINDOW *win, chtype ch);
    int mvinsrawch(int y, int x, chtype ch);
    int mvwinsrawch(WINDOW *win, int y, int x, chtype ch);

    int ins_wch(const cchar_t *wch);
    int wins_wch(WINDOW *win, const cchar_t *wch);
    int mvins_wch(int y, int x, const cchar_t *wch);
    int mvwins_wch(WINDOW *win, int y, int x, const cchar_t *wch);

### Description

   The insch() functions insert a chtype into the window at the
   current or specified cursor position. The cursor is NOT
   advanced. A newline is equivalent to clrtoeol(); tabs are
   expanded; other control characters are converted as with
   unctrl().

   The ins_wch() functions are the wide-character
   equivalents, taking cchar_t pointers rather than chtypes.

   Video attributes can be combined with a character by ORing
   them into the parameter. Text, including attributes, can be
   copied from one place to another using inch() and insch().

   insrawch() etc. are PDCurses-specific wrappers for insch() etc.
   that disable the translation of control characters.

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    insch                       Y       Y       Y
    winsch                      Y       Y       Y
    mvinsch                     Y       Y       Y
    mvwinsch                    Y       Y       Y
    insrawch                    -       -       -
    winsrawch                   -       -       -
    ins_wch                     Y
    wins_wch                    Y
    mvins_wch                   Y
    mvwins_wch                  Y

**man-end****************************************************************/

#include <string.h>

int winsch(WINDOW *win, chtype ch)
{
    int x, y;
    chtype attr;
    bool xlat;

    PDC_LOG(("winsch() - called: win=%p ch=%x (text=%c attr=0x%x)\n",
             win, ch, ch & A_CHARTEXT, ch & A_ATTRIBUTES));

    if (!win)
        return ERR;

    x = win->_curx;
    y = win->_cury;

    if (y > win->_maxy || x > win->_maxx || y < 0 || x < 0)
        return ERR;

    xlat = !SP->raw_out && !(ch & A_ALTCHARSET);
    attr = ch & A_ATTRIBUTES;
    ch &= A_CHARTEXT;

    if (xlat && (ch < ' ' || ch == 0x7f))
    {
        int x2;

        switch (ch)
        {
        case '\t':
            for (x2 = ((x / TABSIZE) + 1) * TABSIZE; x < x2; x++)
            {
                if (winsch(win, attr | ' ') == ERR)
                    return ERR;
            }
            return OK;

        case '\n':
            wclrtoeol(win);
            break;

        case 0x7f:
            if (winsch(win, attr | '?') == ERR)
                return ERR;

            return winsch(win, attr | '^');

        default:
            /* handle control chars */

            if (winsch(win, attr | (ch + '@')) == ERR)
                return ERR;

            return winsch(win, attr | '^');
        }
    }
    else
    {
        int maxx;
        chtype *temp;

        /* If the incoming character doesn't have its own attribute,
           then use the current attributes for the window. If it has
           attributes but not a color component, OR the attributes to
           the current attributes for the window. If it has a color
           component, use the attributes solely from the incoming
           character. */

        if (!(attr & A_COLOR))
            attr |= win->_attrs;

        /* wrs (4/10/93): Apply the same sort of logic for the window
           background, in that it only takes precedence if other color
           attributes are not there and that the background character
           will only print if the printing character is blank. */

        if (!(attr & A_COLOR))
            attr |= win->_bkgd & A_ATTRIBUTES;
        else
            attr |= win->_bkgd & (A_ATTRIBUTES ^ A_COLOR);

        if (ch == ' ')
            ch = win->_bkgd & A_CHARTEXT;

        /* Add the attribute back into the character. */

        ch |= attr;

        maxx = win->_maxx;
        temp = &win->_y[y][x];

        memmove(temp + 1, temp, (maxx - x - 1) * sizeof(chtype));

        win->_lastch[y] = maxx - 1;

        if ((win->_firstch[y] == _NO_CHANGE) || (win->_firstch[y] > x))
            win->_firstch[y] = x;

        *temp = ch;
    }

    PDC_sync(win);

    return OK;
}

int insch(chtype ch)
{
    PDC_LOG(("insch() - called\n"));

    return winsch(stdscr, ch);
}

int mvinsch(int y, int x, chtype ch)
{
    PDC_LOG(("mvinsch() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return winsch(stdscr, ch);
}

int mvwinsch(WINDOW *win, int y, int x, chtype ch)
{
    PDC_LOG(("mvwinsch() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return winsch(win, ch);
}

int winsrawch(WINDOW *win, chtype ch)
{
    PDC_LOG(("winsrawch() - called: win=%p ch=%x "
             "(char=%c attr=0x%x)\n", win, ch,
             ch & A_CHARTEXT, ch & A_ATTRIBUTES));

    if ((ch & A_CHARTEXT) < ' ' || (ch & A_CHARTEXT) == 0x7f)
        ch |= A_ALTCHARSET;

    return winsch(win, ch);
}

int insrawch(chtype ch)
{
    PDC_LOG(("insrawch() - called\n"));

    return winsrawch(stdscr, ch);
}

int mvinsrawch(int y, int x, chtype ch)
{
    PDC_LOG(("mvinsrawch() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return winsrawch(stdscr, ch);
}

int mvwinsrawch(WINDOW *win, int y, int x, chtype ch)
{
    PDC_LOG(("mvwinsrawch() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return winsrawch(win, ch);
}

#ifdef PDC_WIDE
int wins_wch(WINDOW *win, const cchar_t *wch)
{
    PDC_LOG(("wins_wch() - called\n"));

    return wch ? winsch(win, *wch) : ERR;
}

int ins_wch(const cchar_t *wch)
{
    PDC_LOG(("ins_wch() - called\n"));

    return wins_wch(stdscr, wch);
}

int mvins_wch(int y, int x, const cchar_t *wch)
{
    PDC_LOG(("mvins_wch() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    return wins_wch(stdscr, wch);
}

int mvwins_wch(WINDOW *win, int y, int x, const cchar_t *wch)
{
    PDC_LOG(("mvwins_wch() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    return wins_wch(win, wch);
}
#endif
