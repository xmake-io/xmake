--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_windres.lua
--

-- imports
import("lib.detect.find_program")

-- check
function _check(program)
    local objectfile = os.tmpfile() .. ".o"
    local resourcefile  = os.tmpfile() .. ".rc"
    io.writefile(resourcefile, [[
#include <winresrc.h>

VS_VERSION_INFO VERSIONINFO
FILEFLAGSMASK VS_FFI_FILEFLAGSMASK
FILEFLAGS 0x0L
FILEOS VOS_NT_WINDOWS32
FILETYPE VFT_APP
FILESUBTYPE VFT2_UNKNOWN
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "000004B0"
        BEGIN
            VALUE "ProductName", "xmake"
        END
    END
END
    ]])

    os.runv(program, {"-i", resourcefile, "-o", objectfile})
    os.rm(resourcefile)
    os.rm(objectfile)
end

-- find windres
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local windres = find_windres()
-- local windres, version = find_windres({version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    opt.check = _check -- we cannot run `windres --version` to check it, because llvm-mingw/windres always return non-zero
    return find_program(opt.program or "windres", opt)
end
