/************************************************************************
* Author    : Tiago Dionizio (tngd@mega.ist.utl.pt)                     *
* Library   : lcurses - Lua 5 interface to the curses library           *
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
$Id: lpanel.c 17 2007-06-21 15:30:45Z tngd $
Changes:

************************************************************************/

#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include <panel.h>

/*
** =======================================================
** defines
** =======================================================
*/
#define PANELMETA           "curses:panel"
#define UPINDEX             LUA_ENVIRONINDEX

/* ======================================================= */

#define LCP_BOOLOK(n)                       \
    static int lcp_ ## n(lua_State *L)      \
    {                                       \
        PANEL *p = lcp_check(L, 1);         \
        lua_pushboolean(L, B(n(p)));        \
        return 1;                           \
    }

/*
** =======================================================
** privates
** =======================================================
*/
static void lcp_new(lua_State *L, PANEL *np)
{
    if (np)
    {
        PANEL **p = lua_newuserdata(L, sizeof(PANEL*));
        luaL_getmetatable(L, PANELMETA);
        lua_setmetatable(L, -2);
        *p = np;
    }
    else
    {
        lua_pushliteral(L, "failed to create panel");
        lua_error(L);
    }
}

static PANEL *lcp_check(lua_State *L, int index)
{
    PANEL **p = (PANEL**)luaL_checkudata(L, 1, PANELMETA);
    if (p == NULL) luaL_argerror(L, index, "bad curses panel");
    if (*p == NULL) luaL_argerror(L, index, "attempt to use closed curses panel");
    return *p;
}

static PANEL **lcp_get(lua_State *L, int index)
{
    PANEL **p = (PANEL**)luaL_checkudata(L, 1, PANELMETA);
    if (p == NULL) luaL_argerror(L, index, "bad curses panel");
    return p;
}

static int lcp_tostring(lua_State *L)
{
    PANEL **p = lcp_get(L, 1);
    char buff[34];
    if (*p == NULL)
        strcpy(buff, "closed");
    else
        sprintf(buff, "%p", lua_touserdata(L, 1));
    lua_pushfstring(L, "curses panel (%s)", buff);
    return 1;
}

/*
** =======================================================
** panel
** =======================================================
*/

static int lc_new_panel(lua_State *L)
{
    WINDOW *w = lcw_check(L, 1);
    lcp_new(L, new_panel(w));

    /* save window userdata for future use if needed */
    lua_pushlightuserdata(L, w);
    lua_pushvalue(L, 1);
    lua_rawset(L, UPINDEX);

    /* save panel userdata for future use if needed */
    lua_pushlightuserdata(L, *(PANEL**)lua_touserdata(L, 2));
    lua_pushvalue(L, -2);
    lua_rawset(L, UPINDEX);

    return 1;
}

static int lcp_del_panel(lua_State *L)
{
    PANEL **p = lcp_get(L, 1);
    if (*p != NULL)
    {
        /* remove information associated with panel */

        /* remove panel userdata entry */
        lua_pushlightuserdata(L, *p);
        lua_pushnil(L);
        lua_rawset(L, UPINDEX);

        /* remove associated window */
        lua_pushlightuserdata(L, panel_window(*p));
        lua_pushnil(L);
        lua_rawset(L, UPINDEX);

        /* remove panel user data entry */
        lua_pushvalue(L, 1);
        lua_pushnil(L);
        lua_rawset(L, UPINDEX);

        del_panel(*p);
        *p = NULL;
    }
    return 0;
}

LCP_BOOLOK(bottom_panel)
LCP_BOOLOK(top_panel)

static int lcp_show_panel(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);

    if (lua_isnoneornil(L, 2) || lua_toboolean(L, 2))
        lua_pushboolean(L, B(show_panel(p)));
    else
        lua_pushboolean(L, B(hide_panel(p)));

    return 1;
}

/*LCP_BOOLOK(show_panel)*/
LCP_BOOLOK(hide_panel)
LCP_BOOLOK(panel_hidden)

static int lc_update_panels(lua_State *L)
{
    update_panels();
    return 0;
}

static int lcp_panel_window(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);
    WINDOW *w = panel_window(p);

    /* get window userdata */
    lua_pushlightuserdata(L, w);
    lua_rawget(L, UPINDEX);
    return 1;
}

static int lcp_replace_panel(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);
    WINDOW *w = lcw_check(L, 2);
    WINDOW *oldw = panel_window(p);

    if (replace_panel(p, w) == ERR)
    {
        lua_pushboolean(L, 0);
        return 1;
    }

    /* remove entry of old window */
    lua_pushlightuserdata(L, oldw);
    lua_pushnil(L);
    lua_rawset(L, UPINDEX);

    /* and save new window */
    lua_pushlightuserdata(L, oldw);
    lua_pushvalue(L, 2);
    lua_rawset(L, UPINDEX);

    lua_pushboolean(L, 1);
    return 1;
}

static int lcp_move_panel(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);
    int starty = luaL_checkint(L, 2);
    int startx = luaL_checkint(L, 3);

    lua_pushboolean(L, B(move_panel(p, starty, startx)));
    return 1;
}

static int lc_bottom_panel(lua_State *L)
{
    PANEL *ap = panel_above(NULL);

    /* get associated userdata variable */
    lua_pushlightuserdata(L, ap);
    lua_rawget(L, UPINDEX);
    return 1;
}

static int lcp_panel_above(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);
    PANEL *ap = panel_above(p);

    /* get associated userdata variable */
    lua_pushlightuserdata(L, ap);
    lua_rawget(L, UPINDEX);
    return 1;
}

static int lc_top_panel(lua_State *L)
{
    PANEL *bp = panel_below(NULL);

    /* get associated userdata variable */
    lua_pushlightuserdata(L, bp);
    lua_rawget(L, UPINDEX);
    return 1;
}

static int lcp_panel_below(lua_State *L)
{
    PANEL *p = lcp_check(L, 1);
    PANEL *bp = panel_below(p);

    /* get associated userdata variable */
    lua_pushlightuserdata(L, bp);
    lua_rawget(L, UPINDEX);
    return 1;
}

static int lcp_set_panel_userptr(lua_State *L)
{
    lcp_check(L, 1);
    /* instead of checkinf if we have a user data value,
    ** force it's existance without any side effects */
    lua_settop(L, 2);
    lua_rawset(L, UPINDEX);
    return 1;
}

static int lcp_panel_userptr(lua_State *L)
{
    lcp_check(L, 1);
    lua_pushvalue(L, 1);
    lua_rawget(L, UPINDEX);
    return 1;
}

/* ======================================================= */
#define EPF(name) { #name, lcp_ ## name },
static const luaL_reg panellib[] =
{
    /* panel */
    { "close", lcp_del_panel },

    { "make_bottom", lcp_bottom_panel },
    { "make_top", lcp_top_panel },
    { "show", lcp_show_panel },
    { "hide", lcp_hide_panel },
    { "hidden", lcp_panel_hidden },

    { "window", lcp_panel_window },
    { "replace", lcp_replace_panel },
    { "move", lcp_move_panel },

    { "above", lcp_panel_above },
    { "below", lcp_panel_below },

    { "set_userdata", lcp_set_panel_userptr },
    { "userdata", lcp_panel_userptr },

    /* misc */
    {"__gc",        lcp_del_panel}, /* rough safety net */
    {"__tostring",  lcp_tostring},
    {NULL, NULL}
};

#define ECF(name) { #name, lc_ ## name },
static const luaL_reg cursespanellib[] =
{
    /* panel */
    ECF(new_panel)
    ECF(update_panels)
    ECF(bottom_panel)
    ECF(top_panel)

    /* terminator */
    {NULL, NULL}
};

/*
** TODO: add upvalue table with lightuserdata keys and weak keyed
** values containing WINDOWS and PANELS used in above functions
*/
int PANEL_EP (lua_State *L)
{
    /* metatable with used panels and associated windows */
    lua_newtable(L);

    /*
    ** create new metatable for window objects
    */
    luaL_newmetatable(L, PANELMETA);
    lua_pushliteral(L, "__index");
    lua_pushvalue(L, -2);               /* push metatable */
    lua_rawset(L, -3);                  /* metatable.__index = metatable */

    lua_pushvalue(L, -2);               /* upvalue table */
    luaL_openlib(L, NULL, panellib, 1);

    lua_pop(L, 1);                      /* remove metatable from stack */

    /*
    ** create global table with curses methods/variables/constants
    */
    luaL_openlib(L, NULL, cursespanellib, 1);
    return 1;
}
