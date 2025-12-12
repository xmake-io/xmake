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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        binutils.lua
--

-- define module
local sandbox_core_base_binutils = sandbox_core_base_binutils or {}

-- load modules
local binutils = require("base/binutils")
local raise    = require("sandbox/modules/raise")

-- generate c/c++ code from the binary file
function sandbox_core_base_binutils.bin2c(binaryfile, outputfile, opt)
    local ok, errors = binutils.bin2c(binaryfile, outputfile, opt)
    if not ok then
        raise("bin2c: %s", errors or "unknown errors")
    end
end

-- generate object file from the binary file
function sandbox_core_base_binutils.bin2obj(binaryfile, outputfile, opt)
    local ok, errors = binutils.bin2obj(binaryfile, outputfile, opt)
    if not ok then
        raise("bin2obj: %s", errors or "unknown errors")
    end
end


-- read symbols from object file (auto-detect format: ELF, COFF, Mach-O)
function sandbox_core_base_binutils.readsyms(binaryfile)
    local symbols, errors = binutils.readsyms(binaryfile)
    if symbols then
        return symbols
    else
        raise("readsyms: %s", errors or "unknown errors")
    end
end

-- extract static library to directory
function sandbox_core_base_binutils.extractlib(libraryfile, outputdir, opt)
    local ok, errors = binutils.extractlib(libraryfile, outputdir, opt)
    if not ok then
        raise("extractlib: %s", errors or "unknown errors")
    end
end

-- return module
return sandbox_core_base_binutils

