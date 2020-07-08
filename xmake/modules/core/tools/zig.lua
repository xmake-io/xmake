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
-- @file        zig.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- init it
function init(self)
    
    -- init shflags
    self:set("zcshflags", "-dynamic")
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    local argv = {}
    if targetkind == "binary" then
        table.insert(argv, "build-exe")
    elseif targetkind == "static" or targetkind == "shared" then
        table.insert(argv, "build-lib")
    else
        raise("unknown target kind(%s)!", targetkind)
    end
    table.join2(argv, flags, "--output-dir", path.directory(targetfile), "--name", path.basename(targetfile), "--object", objectfiles)
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("build-obj", flags, "--output-dir", path.directory(objectfile), "--name", path.basename(objectfile), sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    os.runv(compargv(self, sourcefile, objectfile, flags))
end

