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
-- @file        kotlinc_native.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)
end

-- make the build arguments list
function buildargv(self, sourcefiles, targetkind, targetfile, flags)
    return self:program(), table.join(flags, sourcefiles, "-o", targetfile)
end

-- build the target file
function build(self, sourcefiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(buildargv(self, sourcefiles, targetkind, targetfile, flags))
    if targetkind == "binary" then
        local targetfile_real = targetfile .. (self:is_plat("windows") and ".exe" or ".kexe")
        if os.isfile(targetfile_real) then
            os.mv(targetfile_real, targetfile)
            if self:is_plat("macosx", "iphoneos") then
                local symbolfile_real = targetfile_real .. ".dSYM"
                local symbolfile = targetfile .. ".dSYM"
                if os.isdir(symbolfile_real) then
                    os.mv(symbolfile_real, symbolfile)
                end
            end
        end
    elseif targetkind == "static" and self:is_plat("windows", "mingw") then
        local headerfile_real = targetfile .. "_api.h"
        local headerfile = path.join(path.directory(targetfile), "lib" .. path.basename(targetfile) .. "_api.h")
        if os.isfile(headerfile_real) then
            os.mv(headerfile_real, headerfile)
        end

        local targetfile_real = path.join(path.directory(targetfile), "lib" .. path.basename(targetfile) .. ".lib.a")
        if os.isfile(targetfile_real) then
            os.mv(targetfile_real, targetfile)
        end
    elseif targetkind == "shared" and self:is_plat("windows", "mingw") then
        local headerfile_real = path.join(path.directory(targetfile), path.basename(targetfile) .. "_api.h")
        local headerfile = path.join(path.directory(targetfile), "lib" .. path.basename(targetfile) .. "_api.h")
        if os.isfile(headerfile_real) then
            os.mv(headerfile_real, headerfile)
        end
    end
end

