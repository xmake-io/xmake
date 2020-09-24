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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        bcsave.lua
--

-- imports
import("core.base.option")
import("lib.luajit.bcsave")

-- the options
local options =
{
    {'s', "strip",       "k",  false,            "Strip the debug info."                      }
,   {nil, "rootname",    "kv", nil,              "Set the display root path name."            }
,   {'o', "outputdir",   "kv", nil,              "Set the output directory of bitcode files." }
,   {'x', "excludedirs", "kv", nil,              "Set the excluded directories."              }
,   {nil, "sourcedir",   "v",  os.programdir(),  "Set the directory of lua source files."     }
}

-- save lua files to bitcode files in the given directory
function save(sourcedir, outputdir, opt)

    -- init source directory and options
    opt = opt or {}
    sourcedir = path.absolute(sourcedir or os.programdir())
    outputdir = outputdir and path.absolute(outputdir) or sourcedir
    assert(os.isdir(sourcedir), "%s not found!", sourcedir)

    -- trace
    print("generating bitcode files from %s ..", sourcedir)

    -- save all lua files to bitcode files
    local total_lua = 0
    local total_bc  = 0
    local pattern = path.join(sourcedir, "**.lua")
    if opt.excludedirs then
        pattern = pattern .. "|" .. opt.excludedirs
    end
    local override = (outputdir == sourcedir)
    for _, luafile in ipairs(os.files(pattern)) do

        -- get relative lua file path
        local relativepath = path.relative(luafile, sourcedir)

        -- get display path
        local displaypath = opt.rootname and path.join(opt.rootname, relativepath) or relativepath

        -- get bitcode file path
        local bcfile = override and os.tmpfile() or path.join(outputdir, relativepath)

        -- generate bitcode file
        -- @note we disable cache to ensure all display paths are correct
        bcsave(luafile, bcfile, {strip = opt.strip, displaypath = displaypath, nocache = true})

        -- trace
        local luasize = os.filesize(luafile)
        local bcsize  = os.filesize(bcfile)
        total_lua = total_lua + luasize
        total_bc  = total_bc + bcsize
        vprint("generating %s (%d => %d) ..", displaypath, luasize, bcsize)

        -- override?
        if override then
            os.cp(bcfile, luafile)
        end
    end

    -- trace
    cprint("${bright}bitcode files have been generated in %s, size: %d => %d", outputdir, total_lua, total_bc)
end

-- main entry
function main(...)

    -- parse arguments
    local argv = {...}
    local opt  = option.parse(argv, options, "Save all lua files to bitcode files."
                                           , ""
                                           , "Usage: xmake l private.utils.bcsave [options]")

    -- save bitcode files
    save(opt.sourcedir, opt.outputdir, opt)
end
