--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        link.lua
--

-- imports
import("core.project.config")

-- init it
function init(self)
    
    -- the architecture
    local arch = config.get("arch")

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then 
        flags_arch = "-machine:x86"
    elseif arch == "x64" then
        flags_arch = "-machine:x64"
    end

    -- init ldflags
    _g.ldflags = { "-nologo", "-dynamicbase", "-nxcompat", flags_arch}

    -- init arflags
    _g.arflags = {"-nologo", flags_arch}

    -- init shflags
    _g.shflags = {"-nologo", flags_arch}

    -- init flags map
    _g.mapflags = 
    {
        -- strip
        ["-s"]                  = ""
    ,   ["-S"]                  = ""
 
        -- others
    ,   ["-ftrapv"]             = ""
    ,   ["-fsanitize=address"]  = ""
    }
end

-- get the property
function get(self, name)
    return _g[name]
end

-- make the symbol flag
function nf_symbol(self, level, target)
    
    -- debug? generate *.pdb file
    local flags = nil
    local targetkind = target:get("kind")
    if level == "debug" and (targetkind == "binary" or targetkind == "shared") then
        if target and target.symbolfile then
            flags = {"-debug", "-pdb:" .. target:symbolfile()}
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

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-libpath:" .. dir
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)

    -- make arguments list
    local argv = table.join(flags, "-out:" .. targetfile, objectfiles)

    -- too long?
    local args = os.args(argv)
    if #args > 4096 then
        local argfile = targetfile .. ".arg"
        io.printf(argfile, args)
        argv = {"@" .. argfile}
    end

    -- ok?
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

