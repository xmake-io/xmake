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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      Adel Vilkov (aka RaZeR-RBI)
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")
-- install package
-- @param name  the package name, e.g. clib::clibs/bytes@0.4.0
-- @param opt   the options, .e.g { verbose = true, out_dir = "clib",
--                                  save = false, save_dev = false }
--
-- @return      true or false
--
function main(name, opt)
    -- find clib
    local clib = find_tool("clib")
    if not clib then
        raise("clib not found!")
    end

    -- default options
    local all_opts = {
        verbose = true,
        out_dir = "clib",
        save = false,
        save_dev = false
    }
    -- copy specified options
    if opt then
        for k, v in ipairs(opt) do
            all_opts[k] = v
        end
    end

    local argv = {"install", name}

    local abs_out = path.join(os.projectdir(), all_opts.out_dir)
    dprint("installing %s to %s", name, abs_out)
    table.insert(argv, "-o " .. abs_out)

    if not all_opts.verbose then
        table.insert(argv, "-q")
    end
    if all_opts.save then
        table.insert(argv, "--save")
    end
    if all_opts.save_dev then
        table.insert(argv, "--save-dev")
    end

    -- do install
    os.vrunv(clib.program, argv)

    -- add a package marker file with install directory
    local cache_dir = path.join(os.projectdir(), ".xmake", "cache", "packages")
    local marker_filename = string.gsub(name, "%/", "=")
    local marker_path = path.join(cache_dir, marker_filename)
    dprint("writing clib marker file for %s to %s", name, marker_filename)
    local marker_file = io.open(marker_path, "w")
    marker_file:write(abs_out)
    marker_file:close()
end