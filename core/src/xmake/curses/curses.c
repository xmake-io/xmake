/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        curses.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "curses"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#ifdef XM_CONFIG_API_HAVE_CURSES
#include "prefix.h"
#include <stdlib.h>
#if defined(PDCURSES)
// fix macro redefinition
#   undef MOUSE_MOVED
#endif
#define NCURSES_MOUSE_VERSION 2
#ifdef TB_COMPILER_IS_MINGW
#   include <ncursesw/curses.h>
#else
#   include <curses.h>
#endif
#if defined(NCURSES_VERSION)
#   include <locale.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define XM_CURSES_STDSCR   "curses.stdscr"
#define XM_CURSES_WINDOW   "curses.window"
#define XM_CURSES_OK(v)    (((v) == ERR) ? 0 : 1)

// define functions
#define XM_CURSES_NUMBER(n) \
    static int xm_curses_ ## n(lua_State* lua) \
    { \
        lua_pushnumber(lua, n()); \
        return 1; \
    }

#define XM_CURSES_NUMBER2(n, v) \
    static int xm_curses_ ## n(lua_State* lua) \
    { \
        lua_pushnumber(lua, v); \
        return 1; \
    }

#define XM_CURSES_BOOL(n) \
    static int xm_curses_ ## n(lua_State* lua) \
    { \
        lua_pushboolean(lua, n()); \
        return 1; \
    }

#define XM_CURSES_BOOLOK(n) \
    static int xm_curses_ ## n(lua_State* lua) \
    { \
        lua_pushboolean(lua, XM_CURSES_OK(n())); \
        return 1; \
    }

#define XM_CURSES_WINDOW_BOOLOK(n) \
    static int xm_curses_window_ ## n(lua_State* lua) \
    { \
        WINDOW* w = xm_curses_window_check(lua, 1); \
        lua_pushboolean(lua, XM_CURSES_OK(n(w))); \
        return 1; \
    }

// define constants
#define XM_CURSES_CONST_(n, v) \
    lua_pushstring(lua, n); \
    lua_pushnumber(lua, v); \
    lua_settable(lua, lua_upvalueindex(1));

#define XM_CURSES_CONST(s)       XM_CURSES_CONST_(#s, s)
#define XM_CURSES_CONST2(s, v)   XM_CURSES_CONST_(#s, v)

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// map key for pdcurses, keeping the keys consistent with ncurses
static int g_mapkey = 0;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static chtype xm_curses_checkch(lua_State* lua, int index)
{
    if (lua_type(lua, index) == LUA_TNUMBER)
        return (chtype)luaL_checknumber(lua, index);
    if (lua_type(lua, index) == LUA_TSTRING)
        return *lua_tostring(lua, index);
#ifdef USE_LUAJIT
    luaL_typerror(lua, index, "chtype");
#endif
    return (chtype)0;
}

// get character and map key
static int xm_curses_window_getch_impl(WINDOW* w)
{
#ifdef PDCURSES
    static int has_key = 0;
    static int temp_key = 0;

    int key;
    if (g_mapkey && has_key)
    {
        has_key = 0;
        return temp_key;
    }

    key = wgetch(w);
    if (key == KEY_RESIZE) resize_term(0, 0);
    if (key == ERR || !g_mapkey) return key;
    if (key >= ALT_A && key <= ALT_Z)
    {
        has_key = 1;
        temp_key = key - ALT_A + 'A';
    }
    else if (key >= ALT_0 && key <= ALT_9)
    {
        has_key = 1;
        temp_key = key - ALT_0 + '0';
    }
    else
    {
        switch (key)
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
    }
    has_key = 1;
    return 27;
#else
    return wgetch(w);
#endif
}

// new a window object
static void xm_curses_window_new(lua_State* lua, WINDOW* nw)
{
    if (nw)
    {
        WINDOW** w = (WINDOW**)lua_newuserdata(lua, sizeof(WINDOW*));
        luaL_getmetatable(lua, XM_CURSES_WINDOW);
        lua_setmetatable(lua, -2);
        *w = nw;
    }
    else
    {
        lua_pushliteral(lua, "failed to create window");
        lua_error(lua);
    }
}

// get window
static WINDOW** xm_curses_window_get(lua_State* lua, int index)
{
    WINDOW** w = (WINDOW**)luaL_checkudata(lua, index, XM_CURSES_WINDOW);
    if (w == NULL) luaL_argerror(lua, index, "bad curses window");
    return w;
}

// get and check window
static WINDOW* xm_curses_window_check(lua_State* lua, int index)
{
    WINDOW** w = xm_curses_window_get(lua, index);
    if (*w == NULL) luaL_argerror(lua, index, "attempt to use closed curses window");
    return *w;
}

// tostring(window)
static int xm_curses_window_tostring(lua_State* lua)
{
    WINDOW** w = xm_curses_window_get(lua, 1);
    char const* s = NULL;
    if (*w) s = (char const*)lua_touserdata(lua, 1);
    lua_pushfstring(lua, "curses window (%s)", s? s : "closed");
    return 1;
}

// window:move(y, x)
static int xm_curses_window_move(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int y = luaL_checkint(lua, 2);
    int x = luaL_checkint(lua, 3);
    lua_pushboolean(lua, XM_CURSES_OK(wmove(w, y, x)));
    return 1;
}

// window:getyx(y, x)
static int xm_curses_window_getyx(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int y, x;
    getyx(w, y, x);
    lua_pushnumber(lua, y);
    lua_pushnumber(lua, x);
    return 2;
}

// window:getmaxyx(y, x)
static int xm_curses_window_getmaxyx(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int y, x;
    getmaxyx(w, y, x);
    lua_pushnumber(lua, y);
    lua_pushnumber(lua, x);
    return 2;
}

// window:delwin()
static int xm_curses_window_delwin(lua_State* lua)
{
    WINDOW** w = xm_curses_window_get(lua, 1);
    if (*w && *w != stdscr)
    {
        delwin(*w);
        *w = NULL;
    }
    return 0;
}

// window:addch(ch)
static int xm_curses_window_addch(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    chtype ch = xm_curses_checkch(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(waddch(w, ch)));
    return 1;
}

// window:addnstr(str)
static int xm_curses_window_addnstr(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    const char* str = luaL_checkstring(lua, 2);
    int n = luaL_optint(lua, 3, -1);
    if (n < 0) n = (int)lua_strlen(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(waddnstr(w, str, n)));
    return 1;
}

// window:keypad(true)
static int xm_curses_window_keypad(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int enabled = lua_isnoneornil(lua, 2) ? 1 : lua_toboolean(lua, 2);
    if (enabled)
    {
        // on WIN32 ALT keys need to be mapped, so to make sure you get the wanted keys,
        // only makes sense when using keypad(true) and echo(false)
        g_mapkey = 1;
    }
    lua_pushboolean(lua, XM_CURSES_OK(keypad(w, enabled)));
    return 1;
}

// window:meta(true)
static int xm_curses_window_meta(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int enabled = lua_toboolean(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(meta(w, enabled)));
    return 1;
}

// window:nodelay(true)
static int xm_curses_window_nodelay(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int enabled = lua_toboolean(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(nodelay(w, enabled)));
    return 1;
}

// window:leaveok(true)
static int xm_curses_window_leaveok(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int enabled = lua_toboolean(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(leaveok(w, enabled)));
    return 1;
}

// window:getch()
static int xm_curses_window_getch(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int c = xm_curses_window_getch_impl(w);
    if (c == ERR) return 0;
    lua_pushnumber(lua, c);
    return 1;
}

// window:attroff(attrs)
static int xm_curses_window_attroff(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int attrs = luaL_checkint(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(wattroff(w, attrs)));
    return 1;
}

// window:attron(attrs)
static int xm_curses_window_attron(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int attrs = luaL_checkint(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(wattron(w, attrs)));
    return 1;
}

// window:attrset(attrs)
static int xm_curses_window_attrset(lua_State* lua)
{
    WINDOW* w = xm_curses_window_check(lua, 1);
    int attrs = luaL_checkint(lua, 2);
    lua_pushboolean(lua, XM_CURSES_OK(wattrset(w, attrs)));
    return 1;
}

// window:copywin(...)
static int xm_curses_window_copywin(lua_State* lua)
{
    WINDOW* srcwin = xm_curses_window_check(lua, 1);
    WINDOW* dstwin = xm_curses_window_check(lua, 2);
    int sminrow = luaL_checkint(lua, 3);
    int smincol = luaL_checkint(lua, 4);
    int dminrow = luaL_checkint(lua, 5);
    int dmincol = luaL_checkint(lua, 6);
    int dmaxrow = luaL_checkint(lua, 7);
    int dmaxcol = luaL_checkint(lua, 8);
    int overlay = lua_toboolean(lua, 9);
    lua_pushboolean(lua, XM_CURSES_OK(copywin(srcwin, dstwin, sminrow,
        smincol, dminrow, dmincol, dmaxrow, dmaxcol, overlay)));
    return 1;
}

// clean window after exiting program
static void xm_curses_cleanup()
{
    if (!isendwin())
    {
        wclear(stdscr);
        wrefresh(stdscr);
        endwin();
    }
}

// register constants
static void xm_curses_register_constants(lua_State* lua)
{
    // colors
    XM_CURSES_CONST(COLOR_BLACK)
    XM_CURSES_CONST(COLOR_RED)
    XM_CURSES_CONST(COLOR_GREEN)
    XM_CURSES_CONST(COLOR_YELLOW)
    XM_CURSES_CONST(COLOR_BLUE)
    XM_CURSES_CONST(COLOR_MAGENTA)
    XM_CURSES_CONST(COLOR_CYAN)
    XM_CURSES_CONST(COLOR_WHITE)

    // alternate character set
    XM_CURSES_CONST(ACS_BLOCK)
    XM_CURSES_CONST(ACS_BOARD)
    XM_CURSES_CONST(ACS_BTEE)
    XM_CURSES_CONST(ACS_TTEE)
    XM_CURSES_CONST(ACS_LTEE)
    XM_CURSES_CONST(ACS_RTEE)
    XM_CURSES_CONST(ACS_LLCORNER)
    XM_CURSES_CONST(ACS_LRCORNER)
    XM_CURSES_CONST(ACS_URCORNER)
    XM_CURSES_CONST(ACS_ULCORNER)
    XM_CURSES_CONST(ACS_LARROW)
    XM_CURSES_CONST(ACS_RARROW)
    XM_CURSES_CONST(ACS_UARROW)
    XM_CURSES_CONST(ACS_DARROW)
    XM_CURSES_CONST(ACS_HLINE)
    XM_CURSES_CONST(ACS_VLINE)
    XM_CURSES_CONST(ACS_BULLET)
    XM_CURSES_CONST(ACS_CKBOARD)
    XM_CURSES_CONST(ACS_LANTERN)
    XM_CURSES_CONST(ACS_DEGREE)
    XM_CURSES_CONST(ACS_DIAMOND)
    XM_CURSES_CONST(ACS_PLMINUS)
    XM_CURSES_CONST(ACS_PLUS)
    XM_CURSES_CONST(ACS_S1)
    XM_CURSES_CONST(ACS_S9)

    // attributes
    XM_CURSES_CONST(A_NORMAL)
    XM_CURSES_CONST(A_STANDOUT)
    XM_CURSES_CONST(A_UNDERLINE)
    XM_CURSES_CONST(A_REVERSE)
    XM_CURSES_CONST(A_BLINK)
    XM_CURSES_CONST(A_DIM)
    XM_CURSES_CONST(A_BOLD)
    XM_CURSES_CONST(A_PROTECT)
    XM_CURSES_CONST(A_INVIS)
    XM_CURSES_CONST(A_ALTCHARSET)
    XM_CURSES_CONST(A_CHARTEXT)

    // key functions
    XM_CURSES_CONST(KEY_BREAK)
    XM_CURSES_CONST(KEY_DOWN)
    XM_CURSES_CONST(KEY_UP)
    XM_CURSES_CONST(KEY_LEFT)
    XM_CURSES_CONST(KEY_RIGHT)
    XM_CURSES_CONST(KEY_HOME)
    XM_CURSES_CONST(KEY_BACKSPACE)

    XM_CURSES_CONST(KEY_DL)
    XM_CURSES_CONST(KEY_IL)
    XM_CURSES_CONST(KEY_DC)
    XM_CURSES_CONST(KEY_IC)
    XM_CURSES_CONST(KEY_EIC)
    XM_CURSES_CONST(KEY_CLEAR)
    XM_CURSES_CONST(KEY_EOS)
    XM_CURSES_CONST(KEY_EOL)
    XM_CURSES_CONST(KEY_SF)
    XM_CURSES_CONST(KEY_SR)
    XM_CURSES_CONST(KEY_NPAGE)
    XM_CURSES_CONST(KEY_PPAGE)
    XM_CURSES_CONST(KEY_STAB)
    XM_CURSES_CONST(KEY_CTAB)
    XM_CURSES_CONST(KEY_CATAB)
    XM_CURSES_CONST(KEY_ENTER)
    XM_CURSES_CONST(KEY_SRESET)
    XM_CURSES_CONST(KEY_RESET)
    XM_CURSES_CONST(KEY_PRINT)
    XM_CURSES_CONST(KEY_LL)
    XM_CURSES_CONST(KEY_A1)
    XM_CURSES_CONST(KEY_A3)
    XM_CURSES_CONST(KEY_B2)
    XM_CURSES_CONST(KEY_C1)
    XM_CURSES_CONST(KEY_C3)
    XM_CURSES_CONST(KEY_BTAB)
    XM_CURSES_CONST(KEY_BEG)
    XM_CURSES_CONST(KEY_CANCEL)
    XM_CURSES_CONST(KEY_CLOSE)
    XM_CURSES_CONST(KEY_COMMAND)
    XM_CURSES_CONST(KEY_COPY)
    XM_CURSES_CONST(KEY_CREATE)
    XM_CURSES_CONST(KEY_END)
    XM_CURSES_CONST(KEY_EXIT)
    XM_CURSES_CONST(KEY_FIND)
    XM_CURSES_CONST(KEY_HELP)
    XM_CURSES_CONST(KEY_MARK)
    XM_CURSES_CONST(KEY_MESSAGE)
#ifdef PDCURSES
    // https://github.com/xmake-io/xmake/issues/1610#issuecomment-971149885
    XM_CURSES_CONST(KEY_C2)
    XM_CURSES_CONST(KEY_A2)
    XM_CURSES_CONST(KEY_B1)
    XM_CURSES_CONST(KEY_B3)
#endif
#if !defined(XCURSES)
#   ifndef NOMOUSE
    XM_CURSES_CONST(KEY_MOUSE)
#   endif
#endif
    XM_CURSES_CONST(KEY_MOVE)
    XM_CURSES_CONST(KEY_NEXT)
    XM_CURSES_CONST(KEY_OPEN)
    XM_CURSES_CONST(KEY_OPTIONS)
    XM_CURSES_CONST(KEY_PREVIOUS)
    XM_CURSES_CONST(KEY_REDO)
    XM_CURSES_CONST(KEY_REFERENCE)
    XM_CURSES_CONST(KEY_REFRESH)
    XM_CURSES_CONST(KEY_REPLACE)
    XM_CURSES_CONST(KEY_RESIZE)
    XM_CURSES_CONST(KEY_RESTART)
    XM_CURSES_CONST(KEY_RESUME)
    XM_CURSES_CONST(KEY_SAVE)
    XM_CURSES_CONST(KEY_SBEG)
    XM_CURSES_CONST(KEY_SCANCEL)
    XM_CURSES_CONST(KEY_SCOMMAND)
    XM_CURSES_CONST(KEY_SCOPY)
    XM_CURSES_CONST(KEY_SCREATE)
    XM_CURSES_CONST(KEY_SDC)
    XM_CURSES_CONST(KEY_SDL)
    XM_CURSES_CONST(KEY_SELECT)
    XM_CURSES_CONST(KEY_SEND)
    XM_CURSES_CONST(KEY_SEOL)
    XM_CURSES_CONST(KEY_SEXIT)
    XM_CURSES_CONST(KEY_SFIND)
    XM_CURSES_CONST(KEY_SHELP)
    XM_CURSES_CONST(KEY_SHOME)
    XM_CURSES_CONST(KEY_SIC)
    XM_CURSES_CONST(KEY_SLEFT)
    XM_CURSES_CONST(KEY_SMESSAGE)
    XM_CURSES_CONST(KEY_SMOVE)
    XM_CURSES_CONST(KEY_SNEXT)
    XM_CURSES_CONST(KEY_SOPTIONS)
    XM_CURSES_CONST(KEY_SPREVIOUS)
    XM_CURSES_CONST(KEY_SPRINT)
    XM_CURSES_CONST(KEY_SREDO)
    XM_CURSES_CONST(KEY_SREPLACE)
    XM_CURSES_CONST(KEY_SRIGHT)
    XM_CURSES_CONST(KEY_SRSUME)
    XM_CURSES_CONST(KEY_SSAVE)
    XM_CURSES_CONST(KEY_SSUSPEND)
    XM_CURSES_CONST(KEY_SUNDO)
    XM_CURSES_CONST(KEY_SUSPEND)
    XM_CURSES_CONST(KEY_UNDO)

    // KEY_Fx  0 <= x <= 63
    XM_CURSES_CONST(KEY_F0)
    XM_CURSES_CONST2(KEY_F1, KEY_F(1))
    XM_CURSES_CONST2(KEY_F2, KEY_F(2))
    XM_CURSES_CONST2(KEY_F3, KEY_F(3))
    XM_CURSES_CONST2(KEY_F4, KEY_F(4))
    XM_CURSES_CONST2(KEY_F5, KEY_F(5))
    XM_CURSES_CONST2(KEY_F6, KEY_F(6))
    XM_CURSES_CONST2(KEY_F7, KEY_F(7))
    XM_CURSES_CONST2(KEY_F8, KEY_F(8))
    XM_CURSES_CONST2(KEY_F9, KEY_F(9))
    XM_CURSES_CONST2(KEY_F10, KEY_F(10))
    XM_CURSES_CONST2(KEY_F11, KEY_F(11))
    XM_CURSES_CONST2(KEY_F12, KEY_F(12))

#if !defined(XCURSES)
#   ifndef NOMOUSE
    // mouse constants
    XM_CURSES_CONST(BUTTON1_RELEASED)
    XM_CURSES_CONST(BUTTON1_PRESSED)
    XM_CURSES_CONST(BUTTON1_CLICKED)
    XM_CURSES_CONST(BUTTON1_DOUBLE_CLICKED)
    XM_CURSES_CONST(BUTTON1_TRIPLE_CLICKED)
    XM_CURSES_CONST(BUTTON2_RELEASED)
    XM_CURSES_CONST(BUTTON2_PRESSED)
    XM_CURSES_CONST(BUTTON2_CLICKED)
    XM_CURSES_CONST(BUTTON2_DOUBLE_CLICKED)
    XM_CURSES_CONST(BUTTON2_TRIPLE_CLICKED)
    XM_CURSES_CONST(BUTTON3_RELEASED)
    XM_CURSES_CONST(BUTTON3_PRESSED)
    XM_CURSES_CONST(BUTTON3_CLICKED)
    XM_CURSES_CONST(BUTTON3_DOUBLE_CLICKED)
    XM_CURSES_CONST(BUTTON3_TRIPLE_CLICKED)
    XM_CURSES_CONST(BUTTON4_RELEASED)
    XM_CURSES_CONST(BUTTON4_PRESSED)
    XM_CURSES_CONST(BUTTON4_CLICKED)
    XM_CURSES_CONST(BUTTON4_DOUBLE_CLICKED)
    XM_CURSES_CONST(BUTTON4_TRIPLE_CLICKED)
    XM_CURSES_CONST(BUTTON_CTRL)
    XM_CURSES_CONST(BUTTON_SHIFT)
    XM_CURSES_CONST(BUTTON_ALT)
    XM_CURSES_CONST(REPORT_MOUSE_POSITION)
    XM_CURSES_CONST(ALL_MOUSE_EVENTS)
#       if NCURSES_MOUSE_VERSION > 1
    XM_CURSES_CONST(BUTTON5_RELEASED)
    XM_CURSES_CONST(BUTTON5_PRESSED)
    XM_CURSES_CONST(BUTTON5_CLICKED)
    XM_CURSES_CONST(BUTTON5_DOUBLE_CLICKED)
    XM_CURSES_CONST(BUTTON5_TRIPLE_CLICKED)
#       endif
#   endif
#endif
}

// init curses
static int xm_curses_initscr(lua_State* lua)
{
    WINDOW* w = initscr();
    if (!w) return 0;
    xm_curses_window_new(lua, w);

#if defined(NCURSES_VERSION)
//    ESCDELAY = 0;
    set_escdelay(0);
#endif

    lua_pushstring(lua, XM_CURSES_STDSCR);
    lua_pushvalue(lua, -2);
    lua_rawset(lua, LUA_REGISTRYINDEX);

    xm_curses_register_constants(lua);

#ifndef PDCURSES
    atexit(xm_curses_cleanup);
#endif
    return 1;
}

static int xm_curses_endwin(lua_State* lua)
{
    endwin();
#ifdef XCURSES
    XCursesExit();
    exit(0);
#endif
    return 0;
}

static int xm_curses_stdscr(lua_State* lua)
{
    lua_pushstring(lua, XM_CURSES_STDSCR);
    lua_rawget(lua, LUA_REGISTRYINDEX);
    return 1;
}

#if !defined(XCURSES) && !defined(NOMOUSE)
static int xm_curses_getmouse(lua_State* lua)
{
    MEVENT e;
    if (getmouse(&e) == OK)
    {
        lua_pushinteger(lua, e.bstate);
        lua_pushinteger(lua, e.x);
        lua_pushinteger(lua, e.y);
        lua_pushinteger(lua, e.z);
        lua_pushinteger(lua, e.id);
        return 5;
    }

    lua_pushnil(lua);
    return 1;
}

static int xm_curses_mousemask(lua_State* lua)
{
    mmask_t m = luaL_checkint(lua, 1);
    mmask_t om;
    m = mousemask(m, &om);
    lua_pushinteger(lua, m);
    lua_pushinteger(lua, om);
    return 2;
}
#endif

static int xm_curses_init_pair(lua_State* lua)
{
    short pair = luaL_checkint(lua, 1);
    short f = luaL_checkint(lua, 2);
    short b = luaL_checkint(lua, 3);

    lua_pushboolean(lua, XM_CURSES_OK(init_pair(pair, f, b)));
    return 1;
}

static int xm_curses_COLOR_PAIR(lua_State* lua)
{
    int n = luaL_checkint(lua, 1);
    lua_pushnumber(lua, COLOR_PAIR(n));
    return 1;
}

static int xm_curses_curs_set(lua_State* lua)
{
    int vis = luaL_checkint(lua, 1);
    int state = curs_set(vis);
    if (state == ERR)
        return 0;

    lua_pushnumber(lua, state);
    return 1;
}

static int xm_curses_napms(lua_State* lua)
{
    int ms = luaL_checkint(lua, 1);
    lua_pushboolean(lua, XM_CURSES_OK(napms(ms)));
    return 1;
}

static int xm_curses_cbreak(lua_State* lua)
{
    if (lua_isnoneornil(lua, 1) || lua_toboolean(lua, 1))
        lua_pushboolean(lua, XM_CURSES_OK(cbreak()));
    else
        lua_pushboolean(lua, XM_CURSES_OK(nocbreak()));
    return 1;
}

static int xm_curses_echo(lua_State* lua)
{
    if (lua_isnoneornil(lua, 1) || lua_toboolean(lua, 1))
        lua_pushboolean(lua, XM_CURSES_OK(echo()));
    else
        lua_pushboolean(lua, XM_CURSES_OK(noecho()));
    return 1;
}

static int xm_curses_nl(lua_State* lua)
{
    if (lua_isnoneornil(lua, 1) || lua_toboolean(lua, 1))
        lua_pushboolean(lua, XM_CURSES_OK(nl()));
    else
        lua_pushboolean(lua, XM_CURSES_OK(nonl()));
    return 1;
}

static int xm_curses_newpad(lua_State* lua)
{
    int nlines = luaL_checkint(lua, 1);
    int ncols = luaL_checkint(lua, 2);
    xm_curses_window_new(lua, newpad(nlines, ncols));
    return 1;
}

XM_CURSES_NUMBER2(COLS, COLS)
XM_CURSES_NUMBER2(LINES, LINES)
XM_CURSES_BOOL(isendwin)
XM_CURSES_BOOLOK(start_color)
XM_CURSES_BOOL(has_colors)
XM_CURSES_BOOLOK(doupdate)
XM_CURSES_WINDOW_BOOLOK(wclear)
XM_CURSES_WINDOW_BOOLOK(wnoutrefresh)

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

static const luaL_Reg g_window_functions[] =
{
    { "close",      xm_curses_window_delwin       },
    { "keypad",     xm_curses_window_keypad       },
    { "meta",       xm_curses_window_meta         },
    { "nodelay",    xm_curses_window_nodelay      },
    { "leaveok",    xm_curses_window_leaveok      },
    { "move",       xm_curses_window_move         },
    { "clear",      xm_curses_window_wclear       },
    { "noutrefresh",xm_curses_window_wnoutrefresh },
    { "attroff",    xm_curses_window_attroff      },
    { "attron",     xm_curses_window_attron       },
    { "attrset",    xm_curses_window_attrset      },
    { "getch",      xm_curses_window_getch        },
    { "getyx",      xm_curses_window_getyx        },
    { "getmaxyx",   xm_curses_window_getmaxyx     },
    { "addch",      xm_curses_window_addch        },
    { "addstr",     xm_curses_window_addnstr      },
    { "copy",       xm_curses_window_copywin      },
    {"__gc",        xm_curses_window_delwin       },
    {"__tostring",  xm_curses_window_tostring     },
    {NULL, NULL                                   }
};

static const luaL_Reg g_curses_functions[] =
{
    { "done",           xm_curses_endwin       },
    { "isdone",         xm_curses_isendwin     },
    { "main_window",    xm_curses_stdscr       },
    { "columns",        xm_curses_COLS         },
    { "lines",          xm_curses_LINES        },
    { "start_color",    xm_curses_start_color  },
    { "has_colors",     xm_curses_has_colors   },
    { "init_pair",      xm_curses_init_pair    },
    { "color_pair",     xm_curses_COLOR_PAIR   },
    { "napms",          xm_curses_napms        },
    { "cursor_set",     xm_curses_curs_set     },
    { "new_pad",        xm_curses_newpad       },
    { "doupdate",       xm_curses_doupdate     },
    { "cbreak",         xm_curses_cbreak       },
    { "echo",           xm_curses_echo         },
    { "nl",             xm_curses_nl           },
#if !defined(XCURSES)
#ifndef NOMOUSE
    { "mousemask",      xm_curses_mousemask    },
    { "getmouse",       xm_curses_getmouse     },
#endif
#endif
    {NULL, NULL}
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementations
 */
int xm_lua_curses_register(lua_State* lua, const char* module)
{
    // create new metatable for window objects
    luaL_newmetatable(lua, XM_CURSES_WINDOW);
    lua_pushliteral(lua, "__index");
    lua_pushvalue(lua, -2);               /* push metatable */
    lua_rawset(lua, -3);                  /* metatable.__index = metatable */
    luaL_setfuncs(lua, g_window_functions, 0);
    lua_pop(lua, 1);                      /* remove metatable from stack */

    // create global table with curses methods/variables/constants
    lua_newtable(lua);
    luaL_setfuncs(lua, g_curses_functions, 0);

    // add curses.init()
    lua_pushstring(lua, "init");
    lua_pushvalue(lua, -2);
    lua_pushcclosure(lua, xm_curses_initscr, 1);
    lua_settable(lua, -3);

    // register global curses module
    lua_setglobal(lua, module);

    /* since version 5.4, the ncurses library decides how to interpret non-ASCII data using the nl_langinfo function.
     * that means that you have to call setlocale() in the application and encode Unicode strings using one of the system’s available encodings.
     *
     * and we need to link libncurses_window.so for drawing vline, hline characters
     */
#if defined(NCURSES_VERSION)
    setlocale(LC_ALL, "");
#endif
    return 1;
}
#endif
