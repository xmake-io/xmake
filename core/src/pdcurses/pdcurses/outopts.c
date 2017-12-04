/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

outopts
-------

### Synopsis

    int clearok(WINDOW *win, bool bf);
    int idlok(WINDOW *win, bool bf);
    void idcok(WINDOW *win, bool bf);
    void immedok(WINDOW *win, bool bf);
    int leaveok(WINDOW *win, bool bf);
    int setscrreg(int top, int bot);
    int wsetscrreg(WINDOW *win, int top, int bot);
    int scrollok(WINDOW *win, bool bf);

    int raw_output(bool bf);

### Description

   With clearok(), if bf is TRUE, the next call to wrefresh() with
   this window will clear the screen completely and redraw the
   entire screen.

   immedok(), called with a second argument of TRUE, causes an
   automatic wrefresh() every time a change is made to the
   specified window.

   Normally, the hardware cursor is left at the location of the
   window being refreshed.  leaveok() allows the cursor to be
   left wherever the update happens to leave it.  It's useful
   for applications where the cursor is not used, since it reduces
   the need for cursor motions.  If possible, the cursor is made
   invisible when this option is enabled.

   wsetscrreg() sets a scrolling region in a window; "top" and
   "bot" are the line numbers for the top and bottom margins. If
   this option and scrollok() are enabled, any attempt to move off
   the bottom margin will cause all lines in the scrolling region
   to scroll up one line. setscrreg() is the stdscr version.

   idlok() and idcok() do nothing in PDCurses, but are provided for
   compatibility with other curses implementations.

   raw_output() enables the output of raw characters using the
   standard *add* and *ins* curses functions (that is, it disables
   translation of control characters).

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    clearok                     Y       Y       Y
    idlok                       Y       Y       Y
    idcok                       Y       -      4.0
    immedok                     Y       -      4.0
    leaveok                     Y       Y       Y
    setscrreg                   Y       Y       Y
    wsetscrreg                  Y       Y       Y
    scrollok                    Y       Y       Y
    raw_output                  -       -       -

**man-end****************************************************************/

int clearok(WINDOW *win, bool bf)
{
    PDC_LOG(("clearok() - called\n"));

    if (!win)
        return ERR;

    win->_clear = bf;

    return OK;
}

int idlok(WINDOW *win, bool bf)
{
    PDC_LOG(("idlok() - called\n"));

    return OK;
}

void idcok(WINDOW *win, bool bf)
{
    PDC_LOG(("idcok() - called\n"));
}

void immedok(WINDOW *win, bool bf)
{
    PDC_LOG(("immedok() - called\n"));

    if (win)
        win->_immed = bf;
}

int leaveok(WINDOW *win, bool bf)
{
    PDC_LOG(("leaveok() - called\n"));

    if (!win)
        return ERR;

    win->_leaveit = bf;

    curs_set(!bf);

    return OK;
}

int setscrreg(int top, int bottom)
{
    PDC_LOG(("setscrreg() - called: top %d bottom %d\n", top, bottom));

    return wsetscrreg(stdscr, top, bottom);
}

int wsetscrreg(WINDOW *win, int top, int bottom)
{
    PDC_LOG(("wsetscrreg() - called: top %d bottom %d\n", top, bottom));

    if (win && 0 <= top && top <= win->_cury &&
        win->_cury <= bottom && bottom < win->_maxy)
    {
        win->_tmarg = top;
        win->_bmarg = bottom;

        return OK;
    }
    else
        return ERR;
}

int scrollok(WINDOW *win, bool bf)
{
    PDC_LOG(("scrollok() - called\n"));

    if (!win)
        return ERR;

    win->_scroll = bf;

    return OK;
}

int raw_output(bool bf)
{
    PDC_LOG(("raw_output() - called\n"));

    SP->raw_out = bf;

    return OK;
}
