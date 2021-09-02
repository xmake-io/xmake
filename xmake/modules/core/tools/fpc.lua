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
-- @file        fpc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.project.target")

-- init it
function init(self)
end

-- make the strip flag
function nf_strip(self, level)
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the optimize flag
function nf_optimize(self, level)
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
    return {"-L", dir}
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)
    local argv = {}
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-Sd", "-Cn", flags, "-FE" .. path.directory(objectfile), sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)
    os.mkdir(path.directory(objectfile))
    os.runv(compargv(self, sourcefile, objectfile, flags))
    os.mv(path.join(path.directory(objectfile), path.basename(sourcefile) .. ".o"), objectfile)
end

