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
-- @file        go.lua
--


-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
    self:set("gcarflags", "")
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps = {
        none = "-gcflags=-N"
    }
    return maps[level]
end


-- make the strip flag
function nf_strip(self, level)
    local maps = {
        debug = {"-ldflags", "-s"}
    ,   all   = {"-ldflags", "-s -w"}
    }
    return maps[level]
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-ldflags", "-L " .. dir}
end

-- make the build arguments list
-- Modern Go uses "go build" command for both compilation and linking
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    local argv = {"build"}
    if flags then
        table.join2(argv, flags)
    end
    table.insert(argv, "-o")
    table.insert(argv, targetfile)

    -- for static library, use buildmode=archive
    if targetkind == "static" then
        table.insert(argv, "-buildmode=archive")
    end

    -- add source files (Go supports building from source file list)
    table.join2(argv, sourcefiles)

    return self:program(), argv
end

-- build the target file (compile and link in one step)
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    local program, argv = buildargv(self, sourcefiles, targetkind, targetfile, flags)
    os.runv(program, argv, {envs = self:runenvs()})
end
