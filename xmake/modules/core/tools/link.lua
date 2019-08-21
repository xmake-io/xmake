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
-- @author      ruki
-- @file        link.lua
--

-- imports
import("core.project.config")
import("private.tools.vstool")

-- init it
function init(self)
   
    -- init ldflags
    self:set("ldflags", "-nologo", "-dynamicbase", "-nxcompat")

    -- init arflags
    self:set("arflags", "-nologo")

    -- init shflags
    self:set("shflags", "-nologo")

    -- init flags map
    self:set("mapflags",
    {
        -- strip
        ["-s"]                  = ""
    ,   ["-S"]                  = ""
 
        -- others
    ,   ["-ftrapv"]             = ""
    ,   ["-fsanitize=address"]  = ""
    })
end

-- get the property
function get(self, name)
    local values = self._INFO[name]
    if name == "ldflags" or name == "arflags" or name == "shflags" then
        -- switch architecture, @note does cache it in init() for generating vs201x project 
        values = table.join(values, "-machine:" .. (config.arch() or "x86"))
    end
    return values
end

-- make the symbol flag
function nf_symbol(self, level, target)
    
    -- debug? generate *.pdb file
    local flags = nil
    local targetkind = target:get("kind")
    if level == "debug" and (targetkind == "binary" or targetkind == "shared") then
        if target and target.symbolfile then
            flags = "-debug -pdb:" .. target:symbolfile()
        else
            flags = "-debug"
        end
    end

    -- none
    return flags
end

-- make the link flag
function nf_link(self, lib)
    return lib .. ".lib"
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-libpath:" .. os.args(path.translate(dir))
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)

    -- init arguments
    local argv = table.join(flags, "-out:" .. targetfile, objectfiles)

    -- too long arguments for windows? 
    opt = opt or {}
    local args = os.args(argv)
    if #args > 1024 and not opt.rawargs then
        local argsfile = os.tmpfile(args) .. ".args.txt" 
        io.writefile(argsfile, args)
        argv = {"@" .. argsfile}
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags, opt)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- use vstool to link and enable vs_unicode_output @see https://github.com/xmake-io/xmake/issues/528
    vstool.runv(linkargv(self, objectfiles, targetkind, targetfile, flags, opt))
end

