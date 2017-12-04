/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

inopts
------

### Synopsis

    int cbreak(void);
    int nocbreak(void);
    int echo(void);
    int noecho(void);
    int halfdelay(int tenths);
    int intrflush(WINDOW *win, bool bf);
    int keypad(WINDOW *win, bool bf);
    int meta(WINDOW *win, bool bf);
    int nl(void);
    int nonl(void);
    int nodelay(WINDOW *win, bool bf);
    int notimeout(WINDOW *win, bool bf);
    int raw(void);
    int noraw(void);
    void noqiflush(void);
    void qiflush(void);
    void timeout(int delay);
    void wtimeout(WINDOW *win, int delay);
    int typeahead(int fildes);

    int crmode(void);
    int nocrmode(void);

### Description

   cbreak() and nocbreak() toggle cbreak mode. In cbreak mode,
   characters typed by the user are made available immediately, and
   erase/kill character processing is not performed.  In nocbreak
   mode, typed characters are buffered until a newline or carriage
   return. Interrupt and flow control characters are unaffected by
   this mode. PDCurses always starts in cbreak mode.

   echo() and noecho() control whether typed characters are echoed
   by the input routine.  Initially, input characters are echoed.
   Subsequent calls to echo() and noecho() do not flush type-ahead.

   halfdelay() is similar to cbreak(), but allows for a time limit
   to be specified, in tenths of a second. This causes getch() to
   block for that period before returning ERR if no key has been
   received.  tenths must be between 1 and 255.

   keypad() controls whether getch() returns function/special keys
   as single key codes (e.g., the left arrow key as KEY_LEFT). Per
   X/Open, the default for keypad mode is OFF. You'll probably want
   it on. With keypad mode off, if a special key is pressed,
   getch() does nothing or returns ERR.

   nodelay() controls whether wgetch() is a non-blocking call. If
   the option is enabled, and no input is ready, wgetch() will
   return ERR. If disabled, wgetch() will hang until input is
   ready.

   nl() enables the translation of a carriage return into a newline
   on input. nonl() disables this. Initially, the translation does
   occur.

   raw() and noraw() toggle raw mode. Raw mode is similar to cbreak
   mode, in that characters typed are immediately passed through to
   the user program.  The difference is that in raw mode, the INTR,
   QUIT, SUSP, and STOP characters are passed through without being
   interpreted, and without generating a signal.

   In PDCurses, the meta() function sets raw mode on or off.

   timeout() and wtimeout() set blocking or non-blocking reads for
   the specified window. The delay is measured in milliseconds. If
   it's negative, a blocking read is used; if zero, then non-
   blocking reads are done -- if no input is waiting, ERR is
   returned immediately. If the delay is positive, the read blocks
   for the delay period; if the period expires, ERR is returned.

   intrflush(), notimeout(), noqiflush(), qiflush() and typeahead()
   do nothing in PDCurses, but are included for compatibility with
   other curses implementations.

   crmode() and nocrmode() are archaic equivalents to cbreak() and
   nocbreak(), respectively.

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    cbreak                      Y       Y       Y
    nocbreak                    Y       Y       Y
    echo                        Y       Y       Y
    noecho                      Y       Y       Y
    halfdelay                   Y       -       Y
    intrflush                   Y       -       Y
    keypad                      Y       -       Y
    meta                        Y       -       Y
    nl                          Y       Y       Y
    nonl                        Y       Y       Y
    nodelay                     Y       -       Y
    notimeout                   Y       -       Y
    raw                         Y       Y       Y
    noraw                       Y       Y       Y
    noqiflush                   Y       -       Y
    qiflush                     Y       -       Y
    timeout                     Y       -       Y
    wtimeout                    Y       -       Y
    typeahead                   Y       -       Y
    crmode                      -
    nocrmode                    -

**man-end****************************************************************/

int cbreak(void)
{
    PDC_LOG(("cbreak() - called\n"));

    SP->cbreak = TRUE;

    return OK;
}

int nocbreak(void)
{
    PDC_LOG(("nocbreak() - called\n"));

    SP->cbreak = FALSE;
    SP->delaytenths = 0;

    return OK;
}

int echo(void)
{
    PDC_LOG(("echo() - called\n"));

    SP->echo = TRUE;

    return OK;
}

int noecho(void)
{
    PDC_LOG(("noecho() - called\n"));

    SP->echo = FALSE;

    return OK;
}

int halfdelay(int tenths)
{
    PDC_LOG(("halfdelay() - called\n"));

    if (tenths < 1 || tenths > 255)
        return ERR;

    SP->delaytenths = tenths;

    return OK;
}

int intrflush(WINDOW *win, bool bf)
{
    PDC_LOG(("intrflush() - called\n"));

    return OK;
}

int keypad(WINDOW *win, bool bf)
{
    PDC_LOG(("keypad() - called\n"));

    if (!win)
        return ERR;

    win->_use_keypad = bf;

    return OK;
}

int meta(WINDOW *win, bool bf)
{
    PDC_LOG(("meta() - called\n"));

    SP->raw_inp = bf;

    return OK;
}

int nl(void)
{
    PDC_LOG(("nl() - called\n"));

    SP->autocr = TRUE;

    return OK;
}

int nonl(void)
{
    PDC_LOG(("nonl() - called\n"));

    SP->autocr = FALSE;

    return OK;
}

int nodelay(WINDOW *win, bool flag)
{
    PDC_LOG(("nodelay() - called\n"));

    if (!win)
        return ERR;

    win->_nodelay = flag;

    return OK;
}

int notimeout(WINDOW *win, bool flag)
{
    PDC_LOG(("notimeout() - called\n"));

    return OK;
}

int raw(void)
{
    PDC_LOG(("raw() - called\n"));

    PDC_set_keyboard_binary(TRUE);
    SP->raw_inp = TRUE;

    return OK;
}

int noraw(void)
{
    PDC_LOG(("noraw() - called\n"));

    PDC_set_keyboard_binary(FALSE);
    SP->raw_inp = FALSE;

    return OK;
}

void noqiflush(void)
{
    PDC_LOG(("noqiflush() - called\n"));
}

void qiflush(void)
{
    PDC_LOG(("qiflush() - called\n"));
}

int typeahead(int fildes)
{
    PDC_LOG(("typeahead() - called\n"));

    return OK;
}

void wtimeout(WINDOW *win, int delay)
{
    PDC_LOG(("wtimeout() - called\n"));

    if (!win)
        return;

    if (delay < 0)
    {
        /* This causes a blocking read on the window, so turn on delay 
           mode */

        win->_nodelay = FALSE;
        win->_delayms = 0;
    }
    else if (!delay)
    {
        /* This causes a non-blocking read on the window, so turn off 
           delay mode */

        win->_nodelay = TRUE;
        win->_delayms = 0;
    }
    else
    {
        /* This causes the read on the window to delay for the number of 
           milliseconds. Also forces the window into non-blocking read 
           mode */

        /*win->_nodelay = TRUE;*/
        win->_delayms = delay;
    }
}

void timeout(int delay)
{
    PDC_LOG(("timeout() - called\n"));

    wtimeout(stdscr, delay);
}

int crmode(void)
{
    PDC_LOG(("crmode() - called\n"));

    return cbreak();
}

int nocrmode(void)
{
    PDC_LOG(("nocrmode() - called\n"));

    return nocbreak();
}
