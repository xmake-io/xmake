#include <xmi.h>
#include <cmark.h>

static int md2html(lua_State* lua)
{
    const char* mdstr = lua_tostring(lua, 1);

    char* htmlstr = cmark_markdown_to_html(mdstr, strlen(mdstr), 0);

    if (htmlstr == NULL)
    {
        lua_pushliteral(lua, "could not convert markdown to html");
        lua_error(lua);
    }

    lua_pushstring(lua, htmlstr);
    free(htmlstr);

    return 1;
}

int luaopen(cmark, lua_State* lua)
{
    static const luaL_Reg funcs[] = {
        {"md2html", md2html},
        {NULL, NULL}
    };
    lua_newtable(lua);
    luaL_setfuncs(lua, funcs, 0);
    return 1;
}
