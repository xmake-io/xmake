/************************************************************************
* Author    : Tiago Dionizio <tiago.dionizio AT gmail.com>              *
* Library   : lcurses - Lua 5.1 interface to the curses library         *
*                                                                       *
* Permission is hereby granted, free of charge, to any person obtaining *
* a copy of this software and associated documentation files (the       *
* "Software"), to deal in the Software without restriction, including   *
* without limitation the rights to use, copy, modify, merge, publish,   *
* distribute, sublicense, and/or sell copies of the Software, and to    *
* permit persons to whom the Software is furnished to do so, subject to *
* the following conditions:                                             *
*                                                                       *
* The above copyright notice and this permission notice shall be        *
* included in all copies or substantial portions of the Software.       *
*                                                                       *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    *
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  *
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  *
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     *
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                *
************************************************************************/

/************************************************************************
$Id: lcurses.c 17 2007-06-21 15:30:45Z tngd $
History:

************************************************************************/

/************************************************************************
Wish-list:
************************************************************************/

/************************************************************************
Notes:
* when user presses a modifier key on WIN32, it seems that the program
  freezes waiting for another keypress... probably waiting to do some
  work on the modifiers and the (next) pressed key (normal key) acting
  as a blocking operation even if delay settings are turned off

  + solved. but now modifier keys will be returned on WIN32. shouldn't a
  problem though, just ignore them.

* printing control characters on unix will not produce printable
  characters like WIN32 does. better use only 'isprint' characters and
  ACS characters (curses characters)

  + solved. to filter characters being output to the screen, set
  curses.map_output(true). this will filter all characters where a
  chtype or chstr is used

  mostly for cui usage.

* on WIN32 ALT keys need to be mapped, so to make sure you get the wanted
  keys, execute curses.map_keyboard(true). only makes sense when using
  keypad(true) and echo(false)

  mostly for cui usage.
************************************************************************/

#ifdef XM_CONFIG_API_HAVE_CURSES

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "luajit.h"
#include "lualib.h"
#include "lauxlib.h"

#include <curses.h>
#include <signal.h>

#if defined(NCURSES_VERSION)
#include <locale.h>
#endif

#if defined(PDCURSES) && (PDC_BUILD < 3100)
# error Please upgrade to PDCurses 3.1 or later
#endif


/*
 * Title: curses
 *   Provides a binding to the curses library for Lua.
 *
 */

/*
** =======================================================
** defines
** =======================================================
*/
static const char *STDSCR_REGISTRY     = "ltui:curses:stdscr";
static const char *WINDOWMETA          = "ltui:curses:window";
static const char *CHSTRMETA           = "ltui:curses:chstr";
static const char *RIPOFF_TABLE        = "ltui:curses:ripoffline";

#define B(v) ((v == ERR) ? 0 : 1)

/* ======================================================= */

#define LC_NUMBER(v)                        \
    static int lc_ ## v(lua_State *L)       \
    {                                       \
        lua_pushnumber(L, v());             \
        return 1;                           \
    }

#define LC_NUMBER2(n,v)                     \
    static int lc_ ## n(lua_State *L)       \
    {                                       \
        lua_pushnumber(L, v);               \
        return 1;                           \
    }

/* ======================================================= */

#define LC_STRING(v)                        \
    static int lc_ ## v(lua_State *L)       \
    {                                       \
        lua_pushstring(L, v());             \
        return 1;                           \
    }

#define LC_STRING2(n,v)                     \
    static int lc_ ## n(lua_State *L)       \
    {                                       \
        lua_pushstring(L, v);               \
        return 1;                           \
    }

/* ======================================================= */

#define LC_BOOL(v)                          \
    static int lc_ ## v(lua_State *L)       \
    {                                       \
        lua_pushboolean(L, v());            \
        return 1;                           \
    }

#define LC_BOOL2(n,v)                       \
    static int lc_ ## n(lua_State *L)       \
    {                                       \
        lua_pushboolean(L, v);              \
        return 1;                           \
    }

/* ======================================================= */

#define LC_BOOLOK(v)                        \
    static int lc_ ## v(lua_State *L)       \
    {                                       \
        lua_pushboolean(L, B(v()));         \
        return 1;                           \
    }

#define LC_BOOLOK2(n,v)                     \
    static int lc_ ## n(lua_State *L)       \
    {                                       \
        lua_pushboolean(L, B(v));           \
        return 1;                           \
    }

/* ======================================================= */

#define LCW_BOOLOK(n)                       \
    static int lcw_ ## n(lua_State *L)      \
    {                                       \
        WINDOW *w = lcw_check(L, 1);        \
        lua_pushboolean(L, B(n(w)));        \
        return 1;                           \
    }


#ifdef DEBUG

#include <stdarg.h>
int clog(char* f, ...)
{
    va_list args;
    FILE *l;

    va_start(args, f);
    l = fopen("lcurses.log", "a");
    vfprintf(l, f, args);
    fprintf(l, "\n");
    fclose(l);
    va_end(args);
    return 1;
}

#endif /* DEBUG */

/* ascii map table
** used on chstr:set and where a chstr is given as a parameter
** if curses.map_output(true) is set */
static chtype ascii_map[256];
static int map_output = FALSE;
static void init_ascii_map();

/* keyboard mapping. to make key association more consistent
** between curses implementations (PDCURSES and ncurses atm) */
static int map_keyboard = FALSE;

/* (un)set usage of output map table */
static int lc_map_keyboard(lua_State *L)
{
    lua_pushboolean(L, map_keyboard);

    if (!lua_isnoneornil(L, 1))
    {
        luaL_checktype(L, 1, LUA_TBOOLEAN);
        map_keyboard = lua_toboolean(L, 1);
    }

    return 1;
}

/* keyboard mapping function, only active if map_keyboard = TRUE */
static int map_getch(WINDOW *w)
{
#ifdef PDCURSES
    static int has_key = FALSE;
    static int temp_key = 0;

    int key;

    if (map_keyboard && has_key)
    {
        has_key = FALSE;
        return temp_key;
    }

    key = wgetch(w);

    /* in case of error or not using key mapping, return the key */
    if (key == ERR || !map_keyboard) return key;

    if (key >= ALT_A && key <= ALT_Z)
    {
        has_key = TRUE;
        temp_key = key - ALT_A + 'A';
    }
    else if (key >= ALT_0 && key <= ALT_9)
    {
        has_key = TRUE;
        temp_key = key - ALT_0 + '0';
    }
    else switch (key)
    {
        case ALT_DEL:       temp_key = KEY_DC;      break;
        case ALT_INS:       temp_key = KEY_IC;      break;
        case ALT_HOME:      temp_key = KEY_HOME;    break;
        case ALT_END:       temp_key = KEY_END;     break;
        case ALT_PGUP:      temp_key = KEY_PPAGE;   break;
        case ALT_PGDN:      temp_key = KEY_NPAGE;   break;
        case ALT_UP:        temp_key = KEY_UP;      break;
        case ALT_DOWN:      temp_key = KEY_DOWN;    break;
        case ALT_RIGHT:     temp_key = KEY_RIGHT;   break;
        case ALT_LEFT:      temp_key = KEY_LEFT;    break;
        case ALT_BKSP:      temp_key = KEY_BACKSPACE; break;

        default: return key;
    }
    has_key = TRUE;
    return 27;
#else
    return wgetch(w);
#endif
}

/*
** =======================================================
** privates
** =======================================================
*/
static void lcw_new(lua_State *L, WINDOW *nw)
{
    if (nw)
    {
        WINDOW **w = (WINDOW**)lua_newuserdata(L, sizeof(WINDOW*));
        luaL_getmetatable(L, WINDOWMETA);
        lua_setmetatable(L, -2);
        *w = nw;
    }
    else
    {
        lua_pushliteral(L, "failed to create window");
        lua_error(L);
    }
}

static WINDOW **lcw_get(lua_State *L, int index)
{
    WINDOW **w = (WINDOW**)luaL_checkudata(L, index, WINDOWMETA);
    if (w == NULL) luaL_argerror(L, index, "bad curses window");
    return w;
}

static WINDOW *lcw_check(lua_State *L, int index)
{
    WINDOW **w = lcw_get(L, index);
    if (*w == NULL) luaL_argerror(L, index, "attempt to use closed curses window");
    return *w;
}

static int lcw_tostring(lua_State *L)
{
    WINDOW **w = lcw_get(L, 1);
    char buff[34];
    if (*w == NULL)
        strcpy(buff, "closed");
    else
        sprintf(buff, "%p", lua_touserdata(L, 1));
    lua_pushfstring(L, "curses window (%s)", buff);
    return 1;
}

/*
** =======================================================
** chtype handling
** =======================================================
*/
static chtype lc_checkch(lua_State *L, int index)
{
    if (lua_type(L, index) == LUA_TNUMBER)
        return (chtype)luaL_checknumber(L, index);
    if (lua_type(L, index) == LUA_TSTRING)
        return *lua_tostring(L, index);

    luaL_typerror(L, index, "chtype");
    /* never executes */
    return (chtype)0;
}

static chtype lc_optch(lua_State *L, int index, chtype def)
{
    if (lua_isnoneornil(L, index))
        return def;
    return lc_checkch(L, index);
}

/****c* classes/chstr
 * FUNCTION
 *   Line drawing buffer.
 *
 * SEE ALSO
 *   curses.new_chstr
 ****/

typedef struct
{
    unsigned int len;
    chtype str[1];
} chstr;
#define CHSTR_SIZE(len) (sizeof(chstr) + len * sizeof(chtype))


/* create new chstr object and leave it in the lua stack */
static chstr* chstr_new(lua_State *L, int len)
{
    if (len < 1)
    {
        lua_pushliteral(L, "invalid chstr length");
        lua_error(L);
    }
    {
        chstr *cs = (chstr*)lua_newuserdata(L, CHSTR_SIZE(len));
        luaL_getmetatable(L, CHSTRMETA);
        lua_setmetatable(L, -2);
        cs->len = len;
        return cs;
    }
}

/* get chstr from lua (convert if needed) */
static chstr* lc_checkchstr(lua_State *L, int index)
{
    chstr *cs = (chstr*)luaL_checkudata(L, index, CHSTRMETA);
    if (cs) return cs;

    luaL_argerror(L, index, "bad curses chstr");
    return NULL;
}

/****f* curses/curses.new_chstr
 * FUNCTION
 *   Create a new line drawing buffer instance.
 *
 * SEE ALSO
 *   chstr
 ****/
static int lc_new_chstr(lua_State *L)
{
    int len = luaL_checkint(L, 1);
    chstr* ncs = chstr_new(L, len);
    memset(ncs->str, ' ', len*sizeof(chtype));
    return 1;
}

/* change the contents of the chstr */
static int chstr_set_str(lua_State *L)
{
    chstr *cs = lc_checkchstr(L, 1);
    int index = luaL_checkint(L, 2);
    const char *str = luaL_checkstring(L, 3);
    int len = (int)lua_strlen(L, 3);
    int attr = (chtype)luaL_optnumber(L, 4, A_NORMAL);
    int rep = luaL_optint(L, 5, 1);
    int i;

    if (index < 0)
        return 0;

    while (rep-- > 0 && index <= (int)cs->len)
    {
        if (index + len - 1 > (int)cs->len)
            len = cs->len - index + 1;

        if (map_output)
        {
            for (i = 0; i < len; ++i)
                cs->str[index + i] = ascii_map[(unsigned char)str[i]] | attr;
        }
        else
        {
            for (i = 0; i < len; ++i)
                cs->str[index + i] = str[i] | attr;
        }
        index += len;
    }

    return 0;
}


/****m* chstr/set_ch
 * FUNCTION
 *   Set a character in the buffer.
 *
 * SYNOPSIS
 *   chstr:set_ch(index, char, attribute [, repeat])
 *
 * EXAMPLE
 *   Set the buffer with 'a's where the first one is capitalized
 *   and has bold.
 *       size = 10
 *       str = curses.new_chstr(10)
 *       str:set_ch(0, 'A', curses.A_BOLD)
 *       str:set_ch(1, 'a', curses.A_NORMAL, size - 1)
 ****/
static int chstr_set_ch(lua_State *L)
{
    chstr* cs = lc_checkchstr(L, 1);
    int index = luaL_checkint(L, 2);
    chtype ch = lc_checkch(L, 3);
    int attr = (chtype)luaL_optnumber(L, 4, A_NORMAL);
    int rep = luaL_optint(L, 5, 1);

    while (rep-- > 0)
    {
        if (index < 0 || index >= (int)cs->len)
            return 0;

        if (map_output && ch <= 255)
            cs->str[index] = ascii_map[ch] | attr;
        else
            cs->str[index] = ch | attr;

        ++index;
    }
    return 0;
}

/* get information from the chstr */
static int chstr_get(lua_State *L)
{
    chstr* cs = lc_checkchstr(L, 1);
    int index = luaL_checkint(L, 2);
    chtype ch;

    if (index < 0 || index >= (int)cs->len)
        return 0;

    ch = cs->str[index];

    lua_pushnumber(L, ch & A_CHARTEXT);
    lua_pushnumber(L, ch & A_ATTRIBUTES);
    lua_pushnumber(L, ch & A_COLOR);
    return 3;
}

/* retrieve chstr length */
static int chstr_len(lua_State *L)
{
    chstr *cs = lc_checkchstr(L, 1);
    lua_pushnumber(L, cs->len);
    return 1;
}

/* duplicate chstr */
static int chstr_dup(lua_State *L)
{
    chstr *cs = lc_checkchstr(L, 1);
    chstr *ncs = chstr_new(L, cs->len);

    memcpy(ncs->str, cs->str, CHSTR_SIZE(cs->len));
    return 1;
}

/* (un)set usage of output map table */
static int lc_map_output(lua_State *L)
{
    lua_pushboolean(L, map_output);

    if (!lua_isnoneornil(L, 1))
    {
        luaL_checktype(L, 1, LUA_TBOOLEAN);
        map_output = lua_toboolean(L, 1);
    }

    return 1;
}

/*
** =======================================================
** initscr
** =======================================================
*/

#define CCR(n, v)                       \
    lua_pushstring(L, n);               \
    lua_pushnumber(L, v);               \
    lua_settable(L, lua_upvalueindex(1));

#define CC(s)       CCR(#s, s)
#define CC2(s, v)   CCR(#s, v)

/*
** these values may be fixed only after initialization, so this is
** called from lc_initscr, after the curses driver is initialized
**
** curses table is kept at upvalue position 1, in case the global
** name is changed by the user or even in the registration phase by
** the developer
**
** some of these values are not constant so need to register
** them directly instead of using a table
*/
static void register_curses_constants(lua_State *L)
{
    /* colors */
    CC(COLOR_BLACK)     CC(COLOR_RED)       CC(COLOR_GREEN)
    CC(COLOR_YELLOW)    CC(COLOR_BLUE)      CC(COLOR_MAGENTA)
    CC(COLOR_CYAN)      CC(COLOR_WHITE)

    /* alternate character set */
    CC(ACS_BLOCK)       CC(ACS_BOARD)

    CC(ACS_BTEE)        CC(ACS_TTEE)
    CC(ACS_LTEE)        CC(ACS_RTEE)
    CC(ACS_LLCORNER)    CC(ACS_LRCORNER)
    CC(ACS_URCORNER)    CC(ACS_ULCORNER)

    CC(ACS_LARROW)      CC(ACS_RARROW)
    CC(ACS_UARROW)      CC(ACS_DARROW)

    CC(ACS_HLINE)       CC(ACS_VLINE)

    CC(ACS_BULLET)      CC(ACS_CKBOARD)     CC(ACS_LANTERN)
    CC(ACS_DEGREE)      CC(ACS_DIAMOND)

    CC(ACS_PLMINUS)     CC(ACS_PLUS)
    CC(ACS_S1)          CC(ACS_S9)

    /* attributes */
    CC(A_NORMAL)        CC(A_STANDOUT)      CC(A_UNDERLINE)
    CC(A_REVERSE)       CC(A_BLINK)         CC(A_DIM)
    CC(A_BOLD)          CC(A_PROTECT)       CC(A_INVIS)
    CC(A_ALTCHARSET)    CC(A_CHARTEXT)

    /* key functions */
    CC(KEY_BREAK)       CC(KEY_DOWN)        CC(KEY_UP)
    CC(KEY_LEFT)        CC(KEY_RIGHT)       CC(KEY_HOME)
    CC(KEY_BACKSPACE)

    CC(KEY_DL)          CC(KEY_IL)          CC(KEY_DC)
    CC(KEY_IC)          CC(KEY_EIC)         CC(KEY_CLEAR)
    CC(KEY_EOS)         CC(KEY_EOL)         CC(KEY_SF)
    CC(KEY_SR)          CC(KEY_NPAGE)       CC(KEY_PPAGE)
    CC(KEY_STAB)        CC(KEY_CTAB)        CC(KEY_CATAB)
    CC(KEY_ENTER)       CC(KEY_SRESET)      CC(KEY_RESET)
    CC(KEY_PRINT)       CC(KEY_LL)          CC(KEY_A1)
    CC(KEY_A3)          CC(KEY_B2)          CC(KEY_C1)
    CC(KEY_C3)          CC(KEY_BTAB)        CC(KEY_BEG)
    CC(KEY_CANCEL)      CC(KEY_CLOSE)       CC(KEY_COMMAND)
    CC(KEY_COPY)        CC(KEY_CREATE)      CC(KEY_END)
    CC(KEY_EXIT)        CC(KEY_FIND)        CC(KEY_HELP)
    CC(KEY_MARK)        CC(KEY_MESSAGE)
#if !defined(XCURSES)
#ifndef NOMOUSE
    CC(KEY_MOUSE)
#endif
#endif
    CC(KEY_MOVE)        CC(KEY_NEXT)        CC(KEY_OPEN)
    CC(KEY_OPTIONS)     CC(KEY_PREVIOUS)    CC(KEY_REDO)
    CC(KEY_REFERENCE)   CC(KEY_REFRESH)     CC(KEY_REPLACE)
    CC(KEY_RESIZE)      CC(KEY_RESTART)     CC(KEY_RESUME)
    CC(KEY_SAVE)        CC(KEY_SBEG)        CC(KEY_SCANCEL)
    CC(KEY_SCOMMAND)    CC(KEY_SCOPY)       CC(KEY_SCREATE)
    CC(KEY_SDC)         CC(KEY_SDL)         CC(KEY_SELECT)
    CC(KEY_SEND)        CC(KEY_SEOL)        CC(KEY_SEXIT)
    CC(KEY_SFIND)       CC(KEY_SHELP)       CC(KEY_SHOME)
    CC(KEY_SIC)         CC(KEY_SLEFT)       CC(KEY_SMESSAGE)
    CC(KEY_SMOVE)       CC(KEY_SNEXT)       CC(KEY_SOPTIONS)
    CC(KEY_SPREVIOUS)   CC(KEY_SPRINT)      CC(KEY_SREDO)
    CC(KEY_SREPLACE)    CC(KEY_SRIGHT)      CC(KEY_SRSUME)
    CC(KEY_SSAVE)       CC(KEY_SSUSPEND)    CC(KEY_SUNDO)
    CC(KEY_SUSPEND)     CC(KEY_UNDO)

    /* KEY_Fx  0 <= x <= 63 */
    CC(KEY_F0)              CC2(KEY_F1, KEY_F(1))   CC2(KEY_F2, KEY_F(2))
    CC2(KEY_F3, KEY_F(3))   CC2(KEY_F4, KEY_F(4))   CC2(KEY_F5, KEY_F(5))
    CC2(KEY_F6, KEY_F(6))   CC2(KEY_F7, KEY_F(7))   CC2(KEY_F8, KEY_F(8))
    CC2(KEY_F9, KEY_F(9))   CC2(KEY_F10, KEY_F(10)) CC2(KEY_F11, KEY_F(11))
    CC2(KEY_F12, KEY_F(12))
#if !defined(XCURSES)
#ifndef NOMOUSE
    /* Mouse Constants */
    CC(BUTTON1_RELEASED); CC(BUTTON1_PRESSED); CC(BUTTON1_CLICKED);
    CC(BUTTON1_DOUBLE_CLICKED); CC(BUTTON1_TRIPLE_CLICKED);
    CC(BUTTON2_RELEASED); CC(BUTTON2_PRESSED); CC(BUTTON2_CLICKED);
    CC(BUTTON2_DOUBLE_CLICKED); CC(BUTTON2_TRIPLE_CLICKED);
    CC(BUTTON3_RELEASED); CC(BUTTON3_PRESSED); CC(BUTTON3_CLICKED);
    CC(BUTTON3_DOUBLE_CLICKED); CC(BUTTON3_TRIPLE_CLICKED);
    CC(BUTTON4_RELEASED); CC(BUTTON4_PRESSED); CC(BUTTON4_CLICKED);
    CC(BUTTON4_DOUBLE_CLICKED); CC(BUTTON4_TRIPLE_CLICKED);
    CC(BUTTON_CTRL); CC(BUTTON_SHIFT); CC(BUTTON_ALT);
    CC(REPORT_MOUSE_POSITION); CC(ALL_MOUSE_EVENTS);
#if NCURSES_MOUSE_VERSION > 1
    CC(BUTTON5_RELEASED); CC(BUTTON5_PRESSED); CC(BUTTON5_CLICKED);
    CC(BUTTON5_DOUBLE_CLICKED); CC(BUTTON5_TRIPLE_CLICKED);
#else
    CC(BUTTON1_RESERVED_EVENT); CC(BUTTON2_RESERVED_EVENT);
    CC(BUTTON3_RESERVED_EVENT); CC(BUTTON4_RESERVED_EVENT);
#endif
#endif
#endif
}

/*
** make sure screen is restored (and cleared) at exit
** (for the situations where program is aborted without a
** proper cleanup)
*/
static void cleanup()
{
    if (!isendwin())
    {
        wclear(stdscr);
        wrefresh(stdscr);
        endwin();
    }
}

static int lc_initscr(lua_State *L)
{
    WINDOW *w;

    /* initialize curses */
    w = initscr();

    /* no longer used, so clean it up */
    lua_pushstring(L, RIPOFF_TABLE);
    lua_pushnil(L);
    lua_settable(L, LUA_REGISTRYINDEX);

    /* failed to initialize */
    if (w == NULL)
        return 0;

    #if defined(NCURSES_VERSION)
    /* acomodate this value for cui keyboard handling */
    ESCDELAY = 0;
    #endif

    /* return stdscr - main window */
    lcw_new(L, w);

    /* save main window on registry */
    lua_pushstring(L, STDSCR_REGISTRY);
    lua_pushvalue(L, -2);
    lua_rawset(L, LUA_REGISTRYINDEX);

    /* setup curses constants - curses.xxx numbers */
    register_curses_constants(L);
    /* setup ascii map table */
    init_ascii_map();

    /* install cleanup handler to help in debugging and screen trashing */
#ifndef PDCURSES
    atexit(cleanup);
#endif
    /* disable interrupt signal
    signal(SIGINT, SIG_IGN);
    signal(SIGBREAK, SIG_IGN);
    signal(SIGTERM, SIG_IGN);*/
    return 1;
}

static int lc_endwin(lua_State *L)
{
    endwin();
#ifdef XCURSES
    XCursesExit();
    exit(0);
#endif
    return 0;
}

LC_BOOL(isendwin)

static int lc_stdscr(lua_State *L)
{
    lua_pushstring(L, STDSCR_REGISTRY);
    lua_rawget(L, LUA_REGISTRYINDEX);
    return 1;
}

LC_NUMBER2(COLS, COLS)
LC_NUMBER2(LINES, LINES)

/*
** =======================================================
** mouse
** =======================================================
*/
#if !defined(XCURSES)
#ifndef NOMOUSE
static int
lc_ungetmouse(lua_State *L)
{
    MEVENT e;
    e.bstate = luaL_checklong(L, 1);
    e.x = luaL_checkint(L, 2);
    e.y = luaL_checkint(L, 3);
    e.z = luaL_checkint(L, 4);
    e.id = luaL_checkint(L, 5);

    lua_pushboolean(L, !(!ungetmouse(&e)));
    return 1;
}

static int
lc_getmouse(lua_State *L)
{
    MEVENT e;
    if (getmouse(&e) == OK)
    {
        lua_pushinteger(L, e.bstate);
        lua_pushinteger(L, e.x);
        lua_pushinteger(L, e.y);
        lua_pushinteger(L, e.z);
        lua_pushinteger(L, e.id);
        return 5;
    }

    lua_pushnil(L);
    return 1;
}

static int
lc_mousemask(lua_State *L)
{
    mmask_t m = luaL_checkint(L, 1);
    mmask_t om;
    m = mousemask(m, &om);
    lua_pushinteger(L, m);
    lua_pushinteger(L, om);
    return 2;
}

static int
lc_mouseinterval(lua_State *L)
{
    if (!lua_gettop(L))
        lua_pushinteger(L, mouseinterval(-1));
    else
        lua_pushinteger(L, mouseinterval(luaL_checkint(L, 1)));
    return 1;
}

#endif
#endif

/*
** =======================================================
** color
** =======================================================
*/

LC_BOOLOK(start_color)
LC_BOOL(has_colors)

static int lc_init_pair(lua_State *L)
{
    short pair = luaL_checkint(L, 1);
    short f = luaL_checkint(L, 2);
    short b = luaL_checkint(L, 3);

    lua_pushboolean(L, B(init_pair(pair, f, b)));
    return 1;
}

static int lc_pair_content(lua_State *L)
{
    short pair = luaL_checkint(L, 1);
    short f;
    short b;
    int ret = pair_content(pair, &f, &b);

    if (ret == ERR)
        return 0;

    lua_pushnumber(L, f);
    lua_pushnumber(L, b);
    return 2;
}

LC_NUMBER2(COLORS, COLORS)
LC_NUMBER2(COLOR_PAIRS, COLOR_PAIRS)

static int lc_COLOR_PAIR(lua_State *L)
{
    int n = luaL_checkint(L, 1);
    lua_pushnumber(L, COLOR_PAIR(n));
    return 1;
}

/*
** =======================================================
** termattrs
** =======================================================
*/

LC_NUMBER(baudrate)
LC_NUMBER(erasechar)
LC_BOOL(has_ic)
LC_BOOL(has_il)
LC_NUMBER(killchar)

static int lc_termattrs(lua_State *L)
{
    if (lua_gettop(L) < 1)
    {
        lua_pushnumber(L, termattrs());
    }
    else
    {
        int a = luaL_checkint(L, 1);
        lua_pushboolean(L, termattrs() & a);
    }
    return 1;
}

LC_STRING(termname)
LC_STRING(longname)

/*
** =======================================================
** kernel
** =======================================================
*/

/* there is no easy way to implement this... */
static lua_State *rip_L = NULL;
static int ripoffline_cb(WINDOW* w, int cols)
{
    static int line = 0;
    int top = lua_gettop(rip_L);

    /* better be safe */
    if (!lua_checkstack(rip_L, 5))
        return 0;

    /* get the table from the registry */
    lua_pushstring(rip_L, RIPOFF_TABLE);
    lua_gettable(rip_L, LUA_REGISTRYINDEX);

    /* get user callback function */
    if (lua_isnil(rip_L, -1)) {
        lua_pop(rip_L, 1);
        return 0;
    }

    lua_rawgeti(rip_L, -1, ++line); /* function to be called */
    lcw_new(rip_L, w);              /* create window object */
    lua_pushnumber(rip_L, cols);    /* push number of columns */

    lua_pcall(rip_L, 2,  0, 0);     /* call the lua function */

    lua_settop(rip_L, top);
    return 1;
}

static int lc_ripoffline(lua_State *L)
{
    static int rip = 0;
    int top_line = lua_toboolean(L, 1);

    if (!lua_isfunction(L, 2))
    {
        lua_pushliteral(L, "invalid callback passed as second parameter");
        lua_error(L);
    }

    /* need to save the lua state somewhere... */
    rip_L = L;

    /* get the table where we are going to save the callbacks */
    lua_pushstring(L, RIPOFF_TABLE);
    lua_gettable(L, LUA_REGISTRYINDEX);

    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        lua_newtable(L);

        lua_pushstring(L, RIPOFF_TABLE);
        lua_pushvalue(L, -2);
        lua_settable(L, LUA_REGISTRYINDEX);
    }

    /* save function callback in registry table */
    lua_pushvalue(L, 2);
    lua_rawseti(L, -2, ++rip);

    /* and tell curses we are going to take the line */
    lua_pushboolean(L, B(ripoffline(top_line ? 1 : -1, ripoffline_cb)));
    return 1;
}

static int lc_curs_set(lua_State *L)
{
    int vis = luaL_checkint(L, 1);
    int state = curs_set(vis);
    if (state == ERR)
        return 0;

    lua_pushnumber(L, state);
    return 1;
}

static int lc_napms(lua_State *L)
{
    int ms = luaL_checkint(L, 1);
    lua_pushboolean(L, B(napms(ms)));
    return 1;
}

/*
** =======================================================
** beep
** =======================================================
*/
LC_BOOLOK(beep)
LC_BOOLOK(flash)


/*
** =======================================================
** window
** =======================================================
*/

static int lc_newwin(lua_State *L)
{
    int nlines  = luaL_checkint(L, 1);
    int ncols   = luaL_checkint(L, 2);
    int begin_y = luaL_checkint(L, 3);
    int begin_x = luaL_checkint(L, 4);

    lcw_new(L, newwin(nlines, ncols, begin_y, begin_x));
    return 1;
}

static int lcw_delwin(lua_State *L)
{
    WINDOW **w = lcw_get(L, 1);
    if (*w != NULL && *w != stdscr)
    {
        delwin(*w);
        *w = NULL;
    }
    return 0;
}

static int lcw_mvwin(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    lua_pushboolean(L, B(mvwin(w, y, x)));
    return 1;
}

static int lcw_subwin(lua_State *L)
{
    WINDOW *orig = lcw_check(L, 1);
    int nlines  = luaL_checkint(L, 2);
    int ncols   = luaL_checkint(L, 3);
    int begin_y = luaL_checkint(L, 4);
    int begin_x = luaL_checkint(L, 5);

    lcw_new(L, subwin(orig, nlines, ncols, begin_y, begin_x));
    return 1;
}

static int lcw_derwin(lua_State *L)
{
    WINDOW *orig = lcw_check(L, 1);
    int nlines  = luaL_checkint(L, 2);
    int ncols   = luaL_checkint(L, 3);
    int begin_y = luaL_checkint(L, 4);
    int begin_x = luaL_checkint(L, 5);

    lcw_new(L, derwin(orig, nlines, ncols, begin_y, begin_x));
    return 1;
}

static int lcw_mvderwin(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int par_y = luaL_checkint(L, 2);
    int par_x = luaL_checkint(L, 3);
    lua_pushboolean(L, B(mvderwin(w, par_y, par_x)));
    return 1;
}

static int lcw_dupwin(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    lcw_new(L, dupwin(w));
    return 1;
}

static int lcw_wsyncup(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    wsyncup(w);
    return 0;
}

static int lcw_syncok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(syncok(w, bf)));
    return 1;
}

static int lcw_wcursyncup(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    wcursyncup(w);
    return 0;
}

static int lcw_wsyncdown(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    wsyncdown(w);
    return 0;
}

/*
** =======================================================
** refresh
** =======================================================
*/
LCW_BOOLOK(wrefresh)
LCW_BOOLOK(wnoutrefresh)
LCW_BOOLOK(redrawwin)

static int lcw_wredrawln(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int beg_line = luaL_checkint(L, 2);
    int num_lines = luaL_checkint(L, 3);
    lua_pushboolean(L, B(wredrawln(w, beg_line, num_lines)));
    return 1;
}

LC_BOOLOK(doupdate)

/*
** =======================================================
** move
** =======================================================
*/

static int lcw_wmove(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    lua_pushboolean(L, B(wmove(w, y, x)));
    return 1;
}

/*
** =======================================================
** scroll
** =======================================================
*/

static int lcw_wscrl(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_checkint(L, 2);
    lua_pushboolean(L, B(wscrl(w, n)));
    return 1;
}

/*
** =======================================================
** touch
** =======================================================
*/

static int lcw_touch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int changed;
    if (lua_isnoneornil(L, 2))
        changed = TRUE;
    else
        changed = lua_toboolean(L, 2);

    if (changed)
        lua_pushboolean(L, B(touchwin(w)));
    else
        lua_pushboolean(L, B(untouchwin(w)));
    return 1;
}

static int lcw_touchline(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int n = luaL_checkint(L, 3);
    int changed;
    if (lua_isnoneornil(L, 4))
        changed = TRUE;
    else
        changed = lua_toboolean(L, 4);
    lua_pushboolean(L, B(wtouchln(w, y, n, changed)));
    return 1;
}

static int lcw_is_linetouched(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int line = luaL_checkint(L, 2);
    lua_pushboolean(L, is_linetouched(w, line));
    return 1;
}

static int lcw_is_wintouched(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    lua_pushboolean(L, is_wintouched(w));
    return 1;
}

/*
** =======================================================
** getyx
** =======================================================
*/

static int lcw_getyx(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y, x;
    getyx(w, y, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

static int lcw_getparyx(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y, x;
    getparyx(w, y, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

static int lcw_getbegyx(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y, x;
    getbegyx(w, y, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

static int lcw_getmaxyx(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y, x;
    getmaxyx(w, y, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, x);
    return 2;
}

/*
** =======================================================
** border
** =======================================================
*/

static int lcw_wborder(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ls = lc_optch(L, 2, 0);
    chtype rs = lc_optch(L, 3, 0);
    chtype ts = lc_optch(L, 4, 0);
    chtype bs = lc_optch(L, 5, 0);
    chtype tl = lc_optch(L, 6, 0);
    chtype tr = lc_optch(L, 7, 0);
    chtype bl = lc_optch(L, 8, 0);
    chtype br = lc_optch(L, 9, 0);

    lua_pushnumber(L, B(wborder(w, ls, rs, ts, bs, tl, tr, bl, br)));
    return 1;
}

static int lcw_box(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype verch = lc_checkch(L, 2);
    chtype horch = lc_checkch(L, 3);

    lua_pushnumber(L, B(box(w, verch, horch)));
    return 1;
}

static int lcw_whline(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    int n = luaL_checkint(L, 3);

    lua_pushnumber(L, B(whline(w, ch, n)));
    return 1;
}

static int lcw_wvline(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    int n = luaL_checkint(L, 3);

    lua_pushnumber(L, B(wvline(w, ch, n)));
    return 1;
}


static int lcw_mvwhline(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    chtype ch = lc_checkch(L, 4);
    int n = luaL_checkint(L, 5);

    lua_pushnumber(L, B(mvwhline(w, y, x, ch, n)));
    return 1;
}

static int lcw_mvwvline(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    chtype ch = lc_checkch(L, 4);
    int n = luaL_checkint(L, 5);

    lua_pushnumber(L, B(mvwvline(w, y, x, ch, n)));
    return 1;
}

/*
** =======================================================
** clear
** =======================================================
*/

LCW_BOOLOK(werase)
LCW_BOOLOK(wclear)
LCW_BOOLOK(wclrtobot)
LCW_BOOLOK(wclrtoeol)

/*
** =======================================================
** slk
** =======================================================
*/
static int lc_slk_init(lua_State *L)
{
    int fmt = luaL_checkint(L, 1);
    lua_pushboolean(L, B(slk_init(fmt)));
    return 1;
}

static int lc_slk_set(lua_State *L)
{
    int labnum = luaL_checkint(L, 1);
    const char* label = luaL_checkstring(L, 2);
    int fmt = luaL_checkint(L, 3);

    lua_pushboolean(L, B(slk_set(labnum, label, fmt)));
    return 1;
}

LC_BOOLOK(slk_refresh)
LC_BOOLOK(slk_noutrefresh)

static int lc_slk_label(lua_State *L)
{
    int labnum = luaL_checkint(L, 1);
    lua_pushstring(L, slk_label(labnum));
    return 1;
}

LC_BOOLOK(slk_clear)
LC_BOOLOK(slk_restore)
LC_BOOLOK(slk_touch)

static int lc_slk_attron(lua_State *L)
{
    chtype attrs = lc_checkch(L, 1);
    lua_pushboolean(L, B(slk_attron(attrs)));
    return 1;
}

static int lc_slk_attroff(lua_State *L)
{
    chtype attrs = lc_checkch(L, 1);
    lua_pushboolean(L, B(slk_attroff(attrs)));
    return 1;
}

static int lc_slk_attrset(lua_State *L)
{
    chtype attrs = lc_checkch(L, 1);
    lua_pushboolean(L, B(slk_attrset(attrs)));
    return 1;
}

/*
** =======================================================
** addch
** =======================================================
*/

static int lcw_waddch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    if (map_output && ch < 256) ch = ascii_map[ch];
    lua_pushboolean(L, B(waddch(w, ch)));
    return 1;
}

static int lcw_mvwaddch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    chtype ch = lc_checkch(L, 4);

    if (map_output && ch < 256) ch = ascii_map[ch];
    lua_pushboolean(L, B(mvwaddch(w, y, x, ch)));
    return 1;
}

static int lcw_wechochar(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);

    lua_pushboolean(L, B(wechochar(w, ch)));
    return 1;
}

/*
** =======================================================
** addchstr
** =======================================================
*/

static int lcw_waddchnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_optint(L, 3, -1);
    chstr *cs = lc_checkchstr(L, 2);

    if (n < 0 || n > (int)cs->len)
        n = cs->len;

    lua_pushboolean(L, B(waddchnstr(w, cs->str, n)));
    return 1;
}

static int lcw_mvwaddchnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    int n = luaL_optint(L, 5, -1);
    chstr *cs = lc_checkchstr(L, 4);

    if (n < 0 || n > (int)cs->len)
        n = cs->len;

    lua_pushboolean(L, B(mvwaddchnstr(w, y, x, cs->str, n)));
    return 1;
}

/*
** =======================================================
** addstr
** =======================================================
*/

static int lcw_waddnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int n = luaL_optint(L, 3, -1);

    if (n < 0) n = (int)lua_strlen(L, 2);

    lua_pushboolean(L, B(waddnstr(w, str, n)));
    return 1;
}

static int lcw_mvwaddnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    const char *str = luaL_checkstring(L, 4);
    int n = luaL_optint(L, 5, -1);

    if (n < 0) n = (int)lua_strlen(L, 4);

    lua_pushboolean(L, B(mvwaddnstr(w, y, x, str, n)));
    return 1;
}

/*
** =======================================================
** bkgd
** =======================================================
*/

static int lcw_wbkgdset(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    wbkgdset(w, ch);
    return 0;
}

static int lcw_wbkgd(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    lua_pushboolean(L, B(wbkgd(w, ch)));
    return 1;
}

static int lcw_getbkgd(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    lua_pushnumber(L, B(getbkgd(w)));
    return 1;
}

/*
** =======================================================
** inopts
** =======================================================
*/

static int lc_cbreak(lua_State *L)
{
    if (lua_isnoneornil(L, 1) || lua_toboolean(L, 1))
        lua_pushboolean(L, B(cbreak()));
    else
        lua_pushboolean(L, B(nocbreak()));
    return 1;
}

static int lc_echo(lua_State *L)
{
    if (lua_isnoneornil(L, 1) || lua_toboolean(L, 1))
        lua_pushboolean(L, B(echo()));
    else
        lua_pushboolean(L, B(noecho()));
    return 1;
}

static int lc_raw(lua_State *L)
{
    if (lua_isnoneornil(L, 1) || lua_toboolean(L, 1))
        lua_pushboolean(L, B(raw()));
    else
        lua_pushboolean(L, B(noraw()));
    return 1;
}

static int lc_halfdelay(lua_State *L)
{
    int tenths = luaL_checkint(L, 1);
    lua_pushboolean(L, B(halfdelay(tenths)));
    return 1;
}

static int lcw_intrflush(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(intrflush(w, bf)));
    return 1;
}

static int lcw_keypad(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_isnoneornil(L, 2) ? 1 : lua_toboolean(L, 2);
    lua_pushboolean(L, B(keypad(w, bf)));
    return 1;
}

static int lcw_meta(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(meta(w, bf)));
    return 1;
}

static int lcw_nodelay(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(nodelay(w, bf)));
    return 1;
}

static int lcw_timeout(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int delay = luaL_checkint(L, 2);
    wtimeout(w, delay);
    return 0;
}

static int lcw_notimeout(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(notimeout(w, bf)));
    return 1;
}

/*
** =======================================================
** outopts
** =======================================================
*/

static int lc_nl(lua_State *L)
{
    if (lua_isnoneornil(L, 1) || lua_toboolean(L, 1))
        lua_pushboolean(L, B(nl()));
    else
        lua_pushboolean(L, B(nonl()));
    return 1;
}

static int lcw_clearok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(clearok(w, bf)));
    return 1;
}

static int lcw_idlok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(idlok(w, bf)));
    return 1;
}

static int lcw_leaveok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(leaveok(w, bf)));
    return 1;
}

static int lcw_scrollok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    lua_pushboolean(L, B(scrollok(w, bf)));
    return 1;
}

static int lcw_idcok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    idcok(w, bf);
    return 0;
}

static int lcw_immedok(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int bf = lua_toboolean(L, 2);
    immedok(w, bf);
    return 0;
}

static int lcw_wsetscrreg(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int top = luaL_checkint(L, 2);
    int bot = luaL_checkint(L, 3);
    lua_pushboolean(L, B(wsetscrreg(w, top, bot)));
    return 1;
}

/*
** =======================================================
** overlay
** =======================================================
*/

static int lcw_overlay(lua_State *L)
{
    WINDOW *srcwin = lcw_check(L, 1);
    WINDOW *dstwin = lcw_check(L, 2);

    lua_pushboolean(L, B(overlay(srcwin, dstwin)));
    return 1;
}

static int lcw_overwrite(lua_State *L)
{
    WINDOW *srcwin = lcw_check(L, 1);
    WINDOW *dstwin = lcw_check(L, 2);

    lua_pushboolean(L, B(overwrite(srcwin, dstwin)));
    return 1;
}

static int lcw_copywin(lua_State *L)
{
    WINDOW *srcwin = lcw_check(L, 1);
    WINDOW *dstwin = lcw_check(L, 2);
    int sminrow = luaL_checkint(L, 3);
    int smincol = luaL_checkint(L, 4);
    int dminrow = luaL_checkint(L, 5);
    int dmincol = luaL_checkint(L, 6);
    int dmaxrow = luaL_checkint(L, 7);
    int dmaxcol = luaL_checkint(L, 8);
    int overlay = lua_toboolean(L, 9);

    lua_pushboolean(L, B(copywin(srcwin, dstwin, sminrow,
        smincol, dminrow, dmincol, dmaxrow, dmaxcol, overlay)));

    return 1;
}

/*
** =======================================================
** util
** =======================================================
*/

static int lc_unctrl(lua_State *L)
{
    chtype c = (chtype)luaL_checknumber(L, 1);
    lua_pushstring(L, unctrl(c));
    return 1;
}

static int lc_keyname(lua_State *L)
{
    int c = luaL_checkint(L, 1);
    lua_pushstring(L, keyname(c));
    return 1;
}

static int lc_delay_output(lua_State *L)
{
    int ms = luaL_checkint(L, 1);
    lua_pushboolean(L, B(delay_output(ms)));
    return 1;
}

static int lc_flushinp(lua_State *L)
{
    lua_pushboolean(L, B(flushinp()));
    return 1;
}

/*
** =======================================================
** delch
** =======================================================
*/

LCW_BOOLOK(wdelch)

static int lcw_mvwdelch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);

    lua_pushboolean(L, B(mvwdelch(w, y, x)));
    return 1;
}

/*
** =======================================================
** deleteln
** =======================================================
*/

LCW_BOOLOK(wdeleteln)
LCW_BOOLOK(winsertln)

static int lcw_winsdelln(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_checkint(L, 2);
    lua_pushboolean(L, B(winsdelln(w, n)));
    return 1;
}

/*
** =======================================================
** getch
** =======================================================
*/

static int lcw_wgetch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int c = map_getch(w);

    if (c == ERR) return 0;

    lua_pushnumber(L, c);
    return 1;
}

static int lcw_mvwgetch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    int c;

    if (wmove(w, y, x) == ERR) return 0;

    c = map_getch(w);

    if (c == ERR) return 0;

    lua_pushnumber(L, c);
    return 1;
}

static int lc_ungetch(lua_State *L)
{
    int c = luaL_checkint(L, 1);
    lua_pushboolean(L, B(ungetch(c)));
    return 1;
}

/*
** =======================================================
** getstr
** =======================================================
*/

static int lcw_wgetnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_optint(L, 2, 0);
    char buf[LUAL_BUFFERSIZE];

    if (n == 0 || n >= LUAL_BUFFERSIZE) n = LUAL_BUFFERSIZE - 1;
    if (wgetnstr(w, buf, n) == ERR)
        return 0;

    lua_pushstring(L, buf);
    return 1;
}

static int lcw_mvwgetnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    int n = luaL_optint(L, 4, -1);
    char buf[LUAL_BUFFERSIZE];

    if (n == 0 || n >= LUAL_BUFFERSIZE) n = LUAL_BUFFERSIZE - 1;
    if (mvwgetnstr(w, y, x, buf, n) == ERR)
        return 0;

    lua_pushstring(L, buf);
    return 1;
}

/*
** =======================================================
** inch
** =======================================================
*/

static int lcw_winch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    lua_pushnumber(L, winch(w));
    return 1;
}

static int lcw_mvwinch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    lua_pushnumber(L, mvwinch(w, y, x));
    return 1;
}

/*
** =======================================================
** inchstr
** =======================================================
*/

static int lcw_winchnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_checkint(L, 2);
    chstr *cs = chstr_new(L, n);

    if (winchnstr(w, cs->str, n) == ERR)
        return 0;

    return 1;
}

static int lcw_mvwinchnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    int n = luaL_checkint(L, 4);
    chstr *cs = chstr_new(L, n);

    if (mvwinchnstr(w, y, x, cs->str, n) == ERR)
        return 0;

    return 1;
}

/*
** =======================================================
** instr
** =======================================================
*/

static int lcw_winnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int n = luaL_checkint(L, 2);
    char buf[LUAL_BUFFERSIZE];

    if (n >= LUAL_BUFFERSIZE) n = LUAL_BUFFERSIZE - 1;
    if (winnstr(w, buf, n) == ERR)
        return 0;

    lua_pushlstring(L, buf, n);
    return 1;
}

static int lcw_mvwinnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    int n = luaL_checkint(L, 4);
    char buf[LUAL_BUFFERSIZE];

    if (n >= LUAL_BUFFERSIZE) n = LUAL_BUFFERSIZE - 1;
    if (mvwinnstr(w, y, x, buf, n) == ERR)
        return 0;

    lua_pushlstring(L, buf, n);
    return 1;
}

/*
** =======================================================
** insch
** =======================================================
*/

static int lcw_winsch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);
    lua_pushboolean(L, B(winsch(w, ch)));
    return 1;
}

static int lcw_mvwinsch(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    chtype ch = lc_checkch(L, 4);
    lua_pushboolean(L, B(mvwinsch(w, y, x, ch)));
    return 1;
}

/*
** =======================================================
** insstr
** =======================================================
*/

static int lcw_winsstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    const char *str = luaL_checkstring(L, 2);
    lua_pushboolean(L, B(winsnstr(w, str, (int)lua_strlen(L, 2))));
    return 1;
}

static int lcw_mvwinsstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    const char *str = luaL_checkstring(L, 4);
    lua_pushboolean(L, B(mvwinsnstr(w, y, x, str, (int)lua_strlen(L, 2))));
    return 1;
}

static int lcw_winsnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int n = luaL_checkint(L, 3);
    lua_pushboolean(L, B(winsnstr(w, str, n)));
    return 1;
}

static int lcw_mvwinsnstr(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int y = luaL_checkint(L, 2);
    int x = luaL_checkint(L, 3);
    const char *str = luaL_checkstring(L, 4);
    int n = luaL_checkint(L, 5);
    lua_pushboolean(L, B(mvwinsnstr(w, y, x, str, n)));
    return 1;
}

/*
** =======================================================
** pad
** =======================================================
*/

static int lc_newpad(lua_State *L)
{
    int nlines = luaL_checkint(L, 1);
    int ncols = luaL_checkint(L, 2);
    lcw_new(L, newpad(nlines, ncols));
    return 1;
}

static int lcw_subpad(lua_State *L)
{
    WINDOW *orig = lcw_check(L, 1);
    int nlines  = luaL_checkint(L, 2);
    int ncols   = luaL_checkint(L, 3);
    int begin_y = luaL_checkint(L, 4);
    int begin_x = luaL_checkint(L, 5);

    lcw_new(L, subpad(orig, nlines, ncols, begin_y, begin_x));
    return 1;
}

static int lcw_prefresh(lua_State *L)
{
    WINDOW *p = lcw_check(L, 1);
    int pminrow = luaL_checkint(L, 2);
    int pmincol = luaL_checkint(L, 3);
    int sminrow = luaL_checkint(L, 4);
    int smincol = luaL_checkint(L, 5);
    int smaxrow = luaL_checkint(L, 6);
    int smaxcol = luaL_checkint(L, 7);

    lua_pushboolean(L, B(prefresh(p, pminrow, pmincol,
        sminrow, smincol, smaxrow, smaxcol)));
    return 1;
}

static int lcw_pnoutrefresh(lua_State *L)
{
    WINDOW *p = lcw_check(L, 1);
    int pminrow = luaL_checkint(L, 2);
    int pmincol = luaL_checkint(L, 3);
    int sminrow = luaL_checkint(L, 4);
    int smincol = luaL_checkint(L, 5);
    int smaxrow = luaL_checkint(L, 6);
    int smaxcol = luaL_checkint(L, 7);

    lua_pushboolean(L, B(pnoutrefresh(p, pminrow, pmincol,
        sminrow, smincol, smaxrow, smaxcol)));
    return 1;
}


static int lcw_pechochar(lua_State *L)
{
    WINDOW *p = lcw_check(L, 1);
    chtype ch = lc_checkch(L, 2);

    lua_pushboolean(L, B(pechochar(p, ch)));
    return 1;
}

/*
** =======================================================
** attr
** =======================================================
*/

static int lcw_wattroff(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int attrs = luaL_checkint(L, 2);
    lua_pushboolean(L, B(wattroff(w, attrs)));
    return 1;
}

static int lcw_wattron(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int attrs = luaL_checkint(L, 2);
    lua_pushboolean(L, B(wattron(w, attrs)));
    return 1;
}

static int lcw_wattrset(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    int attrs = luaL_checkint(L, 2);
    lua_pushboolean(L, B(wattrset(w, attrs)));
    return 1;
}

LCW_BOOLOK(wstandend)
LCW_BOOLOK(wstandout)


/*
** =======================================================
** text functions
** =======================================================
*/

#define LCT(name)                                   \
    static int lca_ ## name(lua_State* L)           \
    {                                               \
        const char *s = luaL_checkstring(L, 1);     \
        lua_pushboolean(L, name(*s));               \
        return 1;                                   \
    }

LCT(isalnum)
LCT(isalpha)
/*LCT(isblank)*/
LCT(iscntrl)
LCT(isdigit)
LCT(isgraph)
LCT(islower)
LCT(isprint)
LCT(ispunct)
LCT(isspace)
LCT(isupper)
LCT(isxdigit)

/*
** =======================================================
** register functions
** =======================================================
*/
/* chstr members */
static const luaL_Reg chstrlib[] =
{
    { "len",        chstr_len       },
    { "set_ch",     chstr_set_ch    },
    { "set_str",    chstr_set_str   },
    { "get",        chstr_get       },
    { "dup",        chstr_dup       },

    { NULL, NULL }
};

#define EWF(name) { #name, lcw_ ## name },
static const luaL_Reg windowlib[] =
{
    /* window */
    { "close", lcw_delwin  },
    { "sub", lcw_subwin },
    { "derive", lcw_derwin },
    { "move_window", lcw_mvwin },
    { "move_derived", lcw_mvderwin },
    { "clone", lcw_dupwin },
    { "syncup", lcw_wsyncup },
    { "syncdown", lcw_wsyncdown },
    { "syncok", lcw_syncok },
    { "cursyncup", lcw_wcursyncup },

    /* inopts */
    EWF(intrflush)
    EWF(keypad)
    EWF(meta)
    EWF(nodelay)
    EWF(timeout)
    EWF(notimeout)

    /* outopts */
    EWF(clearok)
    EWF(idlok)
    EWF(leaveok)
    EWF(scrollok)
    EWF(idcok)
    EWF(immedok)
    EWF(wsetscrreg)

    /* pad */
    EWF(subpad)
    EWF(prefresh)
    EWF(pnoutrefresh)
    EWF(pechochar)

    /* move */
    { "move", lcw_wmove },

    /* scroll */
    { "scroll", lcw_wscrl },

    /* refresh */
    { "refresh", lcw_wrefresh },
    { "noutrefresh", lcw_wnoutrefresh },
    { "redraw", lcw_redrawwin },
    { "redraw_line", lcw_wredrawln },

    /* clear */
    { "erase", lcw_werase },
    { "clear", lcw_wclear },
    { "clear_to_bottom", lcw_wclrtobot },
    { "clear_to_eol", lcw_wclrtoeol },

    /* touch */
    { "touch", lcw_touch },
    { "touch_line", lcw_touchline },
    { "is_line_touched", lcw_is_linetouched },
    { "is_touched", lcw_is_wintouched },

    /* attrs */
    { "attroff", lcw_wattroff },
    { "attron", lcw_wattron },
    { "attrset", lcw_wattrset },
    { "standout", lcw_wstandout },
    { "standend", lcw_wstandend },

    /* getch */
    { "getch", lcw_wgetch },
    { "mvgetch", lcw_mvwgetch },

    /* getyx */
    EWF(getyx)
    EWF(getparyx)
    EWF(getbegyx)
    EWF(getmaxyx)

    /* border */
    { "border", lcw_wborder },
    { "box", lcw_box },
    { "hline", lcw_whline },
    { "vline", lcw_wvline },
    { "mvhline", lcw_mvwhline },
    { "mvvline", lcw_mvwvline },

    /* addch */
    { "addch", lcw_waddch },
    { "mvaddch", lcw_mvwaddch },
    { "echoch", lcw_wechochar },

    /* addchstr */
    { "addchstr", lcw_waddchnstr },
    { "mvaddchstr", lcw_mvwaddchnstr },

    /* addstr */
    { "addstr", lcw_waddnstr },
    { "mvaddstr", lcw_mvwaddnstr },

    /* bkgd */
    EWF(wbkgdset)
    EWF(wbkgd)
    EWF(getbkgd)

    /* overlay */
    { "overlay", lcw_overlay },
    { "overwrite", lcw_overwrite },
    { "copy", lcw_copywin },

    /* delch */
    { "delch", lcw_wdelch },
    { "mvdelch", lcw_mvwdelch },

    /* deleteln */
    { "delete_line", lcw_wdeleteln },
    { "insert_line", lcw_winsertln },
    EWF(winsdelln)

    /* getstr */
    { "getstr", lcw_wgetnstr },
    { "mvgetstr", lcw_mvwgetnstr },

    /* inch */
    EWF(winch)
    EWF(mvwinch)
    EWF(winchnstr)
    EWF(mvwinchnstr)

    /* instr */
    EWF(winnstr)
    EWF(mvwinnstr)

    /* insch */
    EWF(winsch)
    EWF(mvwinsch)

    /* insstr */
    EWF(winsstr)
    EWF(winsnstr)
    EWF(mvwinsstr)
    EWF(mvwinsnstr)

    /* misc */
    {"__gc",        lcw_delwin  }, /* rough safety net */
    {"__tostring",  lcw_tostring},
    {NULL, NULL}
};

#define ECF(name) { #name, lc_ ## name },
#define ETF(name) { #name, lca_ ## name },
static const luaL_Reg curseslib[] =
{
    /* chstr helper function */
    { "new_chstr",      lc_new_chstr    },
    { "map_output",     lc_map_output   },

    /* keyboard mapping */
    { "map_keyboard",   lc_map_keyboard },

    /* initscr */
    #if 0
    { "init",           lc_initscr      },
    #endif
    { "done",           lc_endwin       },
    { "isdone",         lc_isendwin     },
    { "main_window",    lc_stdscr       },
    { "columns",        lc_COLS         },
    { "lines",          lc_LINES        },

    /* color */
    { "start_color",    lc_start_color  },
    { "has_colors",     lc_has_colors   },
    { "init_pair",      lc_init_pair    },
    { "pair_content",   lc_pair_content },
    { "colors",         lc_COLORS       },
    { "color_pairs",    lc_COLOR_PAIRS  },
    { "color_pair",     lc_COLOR_PAIR   },

    /* termattrs */
    { "baudrate",       lc_baudrate     },
    { "erase_char",     lc_erasechar    },
    { "kill_char",      lc_killchar     },
    { "has_insert_char",lc_has_ic       },
    { "has_insert_line",lc_has_il       },
    { "termattrs",      lc_termattrs    },
    { "termname",       lc_termname     },
    { "longname",       lc_longname     },

    /* kernel */
    { "ripoffline",     lc_ripoffline   },
    { "napms",          lc_napms        },
    { "cursor_set",     lc_curs_set     },

    /* beep */
    { "beep",           lc_beep         },
    { "flash",          lc_flash        },

    /* window */
    { "new_window",     lc_newwin       },

    /* pad */
    { "new_pad",        lc_newpad       },

    /* refresh */
    { "doupdate",       lc_doupdate     },

    /* inopts */
    { "cbreak",         lc_cbreak       },
    { "echo",           lc_echo         },
    { "raw",            lc_raw          },
    { "halfdelay",      lc_halfdelay    },

    /* util */
    { "unctrl",         lc_unctrl       },
    { "keyname",        lc_keyname      },
    { "delay_output",   lc_delay_output },
    { "flush_input",    lc_flushinp     },

    /* getch */
    { "ungetch",        lc_ungetch      },

    /* outopts */
    { "nl",             lc_nl           },

#if !defined(XCURSES)
#ifndef NOMOUSE
    { "mousemask",      lc_mousemask    },
    { "mouseinterval",  lc_mouseinterval},
    { "getmouse",       lc_getmouse     },
    { "ungetmouse",     lc_ungetmouse   },
#endif
#endif

    /* slk */
    ECF(slk_init)
    ECF(slk_set)
    ECF(slk_refresh)
    ECF(slk_noutrefresh)
    ECF(slk_label)
    ECF(slk_clear)
    ECF(slk_restore)
    ECF(slk_touch)
    ECF(slk_attron)
    ECF(slk_attroff)
    ECF(slk_attrset)

    /* text functions */
    ETF(isalnum)
    ETF(isalpha)
    /*ETF(isblank)*/
    ETF(iscntrl)
    ETF(isdigit)
    ETF(isgraph)
    ETF(islower)
    ETF(isprint)
    ETF(ispunct)
    ETF(isspace)
    ETF(isupper)
    ETF(isxdigit)

    /* terminator */
    {NULL, NULL}
};


int xm_curses_register (lua_State *L)
{
    /*
    ** create new metatable for window objects
    */
    luaL_newmetatable(L, WINDOWMETA);
    lua_pushliteral(L, "__index");
    lua_pushvalue(L, -2);               /* push metatable */
    lua_rawset(L, -3);                  /* metatable.__index = metatable */
    luaL_openlib(L, NULL, windowlib, 0);

    lua_pop(L, 1);                      /* remove metatable from stack */

    /*
    ** create new metatable for chstr objects
    */
    luaL_newmetatable(L, CHSTRMETA);
    lua_pushliteral(L, "__index");
    lua_pushvalue(L, -2);               /* push metatable */
    lua_rawset(L, -3);                  /* metatable.__index = metatable */
    luaL_openlib(L, NULL, chstrlib, 0);

    lua_pop(L, 1);                      /* remove metatable from stack */


    /*
    ** create global table with curses methods/variables/constants
    */
    lua_newtable(L);
    luaL_register(L, NULL, curseslib);

    lua_pushstring(L, "init");
    lua_pushvalue(L, -2);
    lua_pushcclosure(L, lc_initscr, 1);
    lua_settable(L, -3);

    /* Since version 5.4, the ncurses library decides how to interpret non-ASCII data using the nl_langinfo function. 
     * That means that you have to call setlocale() in the application and encode Unicode strings using one of the system’s available encodings.
     *
     * And we need link libncursesw.so for drawing vline, hline characters
     */
#if defined(NCURSES_VERSION)
    setlocale(LC_ALL, "");
#endif
    return 1;
}


/* initialize the character map table with the known values after
** curses initialization (for ACS_xxx values) */
static void init_ascii_map()
{
    ascii_map[  0] = 32;            ascii_map[  1] = 79;            ascii_map[  2] = 79;            ascii_map[  3] = 111;
    ascii_map[  4] = ACS_DIAMOND;   ascii_map[  5] = 111;           ascii_map[  6] = 111;           ascii_map[  7] = 111;
    ascii_map[  8] = 111;           ascii_map[  9] = 111;           ascii_map[ 10] = 111;           ascii_map[ 11] = 111;
    ascii_map[ 12] = 33;            ascii_map[ 13] = 33;            ascii_map[ 14] = 33;            ascii_map[ 15] = 42;
    ascii_map[ 16] = ACS_RARROW;    ascii_map[ 17] = ACS_LARROW;    ascii_map[ 18] = 124;           ascii_map[ 19] = 33;
    ascii_map[ 20] = 33;            ascii_map[ 21] = 79;            ascii_map[ 22] = 95;            ascii_map[ 23] = 124;
    ascii_map[ 24] = ACS_UARROW;    ascii_map[ 25] = ACS_DARROW;    ascii_map[ 26] = ACS_RARROW;    ascii_map[ 27] = ACS_LARROW;
    ascii_map[ 28] = ACS_LLCORNER;  ascii_map[ 29] = 45;            ascii_map[ 30] = ACS_UARROW;    ascii_map[ 31] = ACS_DARROW;
    ascii_map[ 32] = 32;            ascii_map[ 33] = 33;            ascii_map[ 34] = 34;            ascii_map[ 35] = 35;
    ascii_map[ 36] = 36;            ascii_map[ 37] = 37;            ascii_map[ 38] = 38;            ascii_map[ 39] = 39;
    ascii_map[ 40] = 40;            ascii_map[ 41] = 41;            ascii_map[ 42] = 42;            ascii_map[ 43] = 43;
    ascii_map[ 44] = 44;            ascii_map[ 45] = 45;            ascii_map[ 46] = 46;            ascii_map[ 47] = 47;
    ascii_map[ 48] = 48;            ascii_map[ 49] = 49;            ascii_map[ 50] = 50;            ascii_map[ 51] = 51;
    ascii_map[ 52] = 52;            ascii_map[ 53] = 53;            ascii_map[ 54] = 54;            ascii_map[ 55] = 55;
    ascii_map[ 56] = 56;            ascii_map[ 57] = 57;            ascii_map[ 58] = 58;            ascii_map[ 59] = 59;
    ascii_map[ 60] = 60;            ascii_map[ 61] = 61;            ascii_map[ 62] = 62;            ascii_map[ 63] = 63;
    ascii_map[ 64] = 64;            ascii_map[ 65] = 65;            ascii_map[ 66] = 66;            ascii_map[ 67] = 67;
    ascii_map[ 68] = 68;            ascii_map[ 69] = 69;            ascii_map[ 70] = 70;            ascii_map[ 71] = 71;
    ascii_map[ 72] = 72;            ascii_map[ 73] = 73;            ascii_map[ 74] = 74;            ascii_map[ 75] = 75;
    ascii_map[ 76] = 76;            ascii_map[ 77] = 77;            ascii_map[ 78] = 78;            ascii_map[ 79] = 79;
    ascii_map[ 80] = 80;            ascii_map[ 81] = 81;            ascii_map[ 82] = 82;            ascii_map[ 83] = 83;
    ascii_map[ 84] = 84;            ascii_map[ 85] = 85;            ascii_map[ 86] = 86;            ascii_map[ 87] = 87;
    ascii_map[ 88] = 88;            ascii_map[ 89] = 89;            ascii_map[ 90] = 90;            ascii_map[ 91] = 91;
    ascii_map[ 92] = 92;            ascii_map[ 93] = 93;            ascii_map[ 94] = 94;            ascii_map[ 95] = 95;
    ascii_map[ 96] = 96;            ascii_map[ 97] = 97;            ascii_map[ 98] = 98;            ascii_map[ 99] = 99;
    ascii_map[100] = 100;           ascii_map[101] = 101;           ascii_map[102] = 102;           ascii_map[103] = 103;
    ascii_map[104] = 104;           ascii_map[105] = 105;           ascii_map[106] = 106;           ascii_map[107] = 107;
    ascii_map[108] = 108;           ascii_map[109] = 109;           ascii_map[110] = 110;           ascii_map[111] = 111;
    ascii_map[112] = 112;           ascii_map[113] = 113;           ascii_map[114] = 114;           ascii_map[115] = 115;
    ascii_map[116] = 116;           ascii_map[117] = 117;           ascii_map[118] = 118;           ascii_map[119] = 119;
    ascii_map[120] = 120;           ascii_map[121] = 121;           ascii_map[122] = 122;           ascii_map[123] = 123;
    ascii_map[124] = 124;           ascii_map[125] = 125;           ascii_map[126] = 126;           ascii_map[127] = 100;
    ascii_map[128] = 99;            ascii_map[129] = 117;           ascii_map[130] = 101;           ascii_map[131] = 97;
    ascii_map[132] = 97;            ascii_map[133] = 97;            ascii_map[134] = 97;            ascii_map[135] = 99;
    ascii_map[136] = 101;           ascii_map[137] = 101;           ascii_map[138] = 101;           ascii_map[139] = 105;
    ascii_map[140] = 105;           ascii_map[141] = 105;           ascii_map[142] = 97;            ascii_map[143] = 97;
    ascii_map[144] = 101;           ascii_map[145] = 97;            ascii_map[146] = 102;           ascii_map[147] = 111;
    ascii_map[148] = 111;           ascii_map[149] = 111;           ascii_map[150] = 117;           ascii_map[151] = 117;
    ascii_map[152] = 121;           ascii_map[153] = 79;            ascii_map[154] = 85;            ascii_map[155] = 99;
    ascii_map[156] = 76;            ascii_map[157] = 89;            ascii_map[158] = 80;            ascii_map[159] = 102;
    ascii_map[160] = 97;            ascii_map[161] = 105;           ascii_map[162] = 111;           ascii_map[163] = 117;
    ascii_map[164] = 110;           ascii_map[165] = 78;            ascii_map[166] = 45;            ascii_map[167] = 45;
    ascii_map[168] = 63;            ascii_map[169] = ACS_ULCORNER;  ascii_map[170] = ACS_URCORNER;  ascii_map[171] = 47;
    ascii_map[172] = 47;            ascii_map[173] = 33;            ascii_map[174] = ACS_LARROW;    ascii_map[175] = ACS_RARROW;
    ascii_map[176] = ACS_BOARD;     ascii_map[177] = ACS_CKBOARD;   ascii_map[178] = ACS_CKBOARD;   ascii_map[179] = ACS_VLINE;
    ascii_map[180] = ACS_RTEE;      ascii_map[181] = ACS_RTEE;      ascii_map[182] = ACS_RTEE;      ascii_map[183] = ACS_URCORNER;
    ascii_map[184] = ACS_URCORNER;  ascii_map[185] = ACS_RTEE;      ascii_map[186] = ACS_VLINE;     ascii_map[187] = ACS_URCORNER;
    ascii_map[188] = ACS_LRCORNER;  ascii_map[189] = ACS_LRCORNER;  ascii_map[190] = ACS_LRCORNER;  ascii_map[191] = ACS_URCORNER;
    ascii_map[192] = ACS_LLCORNER;  ascii_map[193] = ACS_BTEE;      ascii_map[194] = ACS_TTEE;      ascii_map[195] = ACS_LTEE;
    ascii_map[196] = ACS_HLINE;     ascii_map[197] = ACS_PLUS;      ascii_map[198] = ACS_LTEE;      ascii_map[199] = ACS_LTEE;
    ascii_map[200] = ACS_LLCORNER;  ascii_map[201] = ACS_ULCORNER;  ascii_map[202] = ACS_BTEE;      ascii_map[203] = ACS_TTEE;
    ascii_map[204] = ACS_LTEE;      ascii_map[205] = ACS_HLINE;     ascii_map[206] = ACS_PLUS;      ascii_map[207] = ACS_BTEE;
    ascii_map[208] = ACS_BTEE;      ascii_map[209] = ACS_TTEE;      ascii_map[210] = ACS_TTEE;      ascii_map[211] = ACS_LLCORNER;
    ascii_map[212] = ACS_LLCORNER;  ascii_map[213] = ACS_ULCORNER;  ascii_map[214] = ACS_ULCORNER;  ascii_map[215] = ACS_PLUS;
    ascii_map[216] = ACS_PLUS;      ascii_map[217] = ACS_LRCORNER;  ascii_map[218] = ACS_ULCORNER;  ascii_map[219] = ACS_BLOCK;
    ascii_map[220] = ACS_BLOCK;     ascii_map[221] = ACS_BLOCK;     ascii_map[222] = ACS_BLOCK;     ascii_map[223] = ACS_BLOCK;
    ascii_map[224] = 97;            ascii_map[225] = 98;            ascii_map[226] = 105;           ascii_map[227] = 112;
    ascii_map[228] = 101;           ascii_map[229] = 111;           ascii_map[230] = 117;           ascii_map[231] = 121;
    ascii_map[232] = 111;           ascii_map[233] = 111;           ascii_map[234] = 111;           ascii_map[235] = 111;
    ascii_map[236] = 111;           ascii_map[237] = 111;           ascii_map[238] = 69;            ascii_map[239] = 110;
    ascii_map[240] = 61;            ascii_map[241] = 43;            ascii_map[242] = 62;            ascii_map[243] = 60;
    ascii_map[244] = 40;            ascii_map[245] = 41;            ascii_map[246] = 45;            ascii_map[247] = 61;
    ascii_map[248] = ACS_DEGREE;    ascii_map[249] = 46;            ascii_map[250] = 46;            ascii_map[251] = 86;
    ascii_map[252] = 110;           ascii_map[253] = 50;            ascii_map[254] = ACS_BULLET;    ascii_map[255] = 32;
}

#endif
