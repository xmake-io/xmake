#include <xmi.h>
#include <iostream>
#include <fstream>
#include <vector>

using namespace std;

static int generate(lua_State* lua) {
    const char* inputfile = lua_tostring(lua, 1);
    const char* outputfile = lua_tostring(lua, 2);

    ifstream src_file(inputfile, ios::in | ios::binary);
    if (!src_file) {
        return 1;
    }
    vector<char> buffer(istreambuf_iterator<char>(src_file), {});
    src_file.close();

    ofstream dst_file(outputfile, ios::out);
    if (!dst_file) {
        return 1;
    }

    dst_file << "unsigned char g_codegen_data[] = {";
    for (auto byte : buffer) {
        dst_file << "0x" << hex << (int)(unsigned char)byte << ",";
    }
    dst_file << "0};" << endl;
    dst_file.close();
    return 0;
}

int luaopen(foo, lua_State* lua) {
    static const luaL_Reg funcs[] = {
        {"generate", generate},
        {NULL, NULL}
    };
    lua_newtable(lua);
    luaL_setfuncs(lua, funcs, 0);
    return 1;
}

