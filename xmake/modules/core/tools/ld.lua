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
-- @file        ld.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)

    -- init shflags
    self:set("shflags", "-shared")

    -- add -fPIC for shared
    if not is_plat("windows", "mingw") then
        self:add("shflags", "-fPIC")
        self:add("shared.cxflags", "-fPIC")
    end
end

-- make the strip flag
function nf_strip(self, level)
    local maps = 
    {   
        debug = "-S"
    ,   all   = "-s"
    }

    local plat = config.plat()
    if plat == "macosx" or plat == "iphoneos" then
        maps.all   = "-Wl,-x"
        maps.debug = "-Wl,-S"
    end
    return maps[level]
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-L" .. os.args(path.translate(dir))
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)

    -- init arguments
    local argv = table.join("-o", targetfile, objectfiles, flags)

    -- too long arguments for windows? 
    if is_host("windows") then
        opt = opt or {}
        local args = os.args(argv, {escape = true})
        if #args > 1024 and not opt.rawargs then
            local argsfile = os.tmpfile(args) .. ".args.txt" 
            io.writefile(argsfile, args)
            argv = {"@" .. argsfile}
        end
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

