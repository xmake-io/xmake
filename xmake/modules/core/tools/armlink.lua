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
-- @file        armlink.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("utils.progress")

function init(self)
end

-- make the link flag
function nf_link(self, lib)
    return "lib" .. lib .. ".a"
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"--userlibpath", dir}
end

-- make runtime flag
function nf_runtime(self, runtime)
    if runtime == "microlib" then
        return "--library_type=microlib"
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    local argv = table.join("-o", targetfile, objectfiles, flags)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
        if #argv > 0 and argv[1] and argv[1]:startswith("@") then
            argv[1] = argv[1]:replace("@", "", {plain = true})
            table.insert(argv, 1, "--via")
        end
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

