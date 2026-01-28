#include "prefix.h"

tb_int_t xm_io_parse_pe(lua_State* lua) {
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // open file
    tb_file_ref_t file = tb_file_init(path, TB_FILE_MODE_RO);
    if (!file) {
        lua_pushnil(lua);
        lua_pushfstring(lua, "cannot open file: %s", path);
        return 2;
    }

    // read dos header
    tb_byte_t buffer[1024];
    if (tb_file_read(file, buffer, 0x40)) {
        // check MZ
        if (buffer[0] == 'M' && buffer[1] == 'Z') {
            // get pe offset
            tb_uint32_t pe_offset = 0;
            // e_lfanew is at 0x3c
            pe_offset = tb_bits_get_u32_le(buffer + 0x3c);
            
            // seek to pe header
            if (tb_file_seek(file, pe_offset, TB_FILE_SEEK_BEG) == pe_offset) {
                 if (tb_file_read(file, buffer, 24)) { // Signature(4) + FileHeader(20)
                      // check PE signature
                      if (buffer[0] == 'P' && buffer[1] == 'E' && buffer[2] == 0 && buffer[3] == 0) {
                          // get machine
                          tb_uint16_t machine = tb_bits_get_u16_le(buffer + 4);
                          
                          lua_newtable(lua);
                          
                          lua_pushstring(lua, "arch");
                          tb_char_t const* arch = tb_null;
                          switch (machine) {
                              case 0x014c: arch = "x86"; break;
                              case 0x8664: arch = "x64"; break;
                              case 0xAA64: arch = "arm64"; break; 
                              case 0x01c0: arch = "arm"; break; 
                              case 0x01c4: arch = "arm"; break; 
                          }
                          if (arch) {
                              lua_pushstring(lua, arch);
                              lua_settable(lua, -3);
                          } else {
                               lua_pop(lua, 1); // pop "arch"
                          }
                           
                          tb_file_exit(file);
                          return 1; 
                      }
                 }
            }
        }
    }

    tb_file_exit(file);
    lua_pushnil(lua);
    return 1;
}
