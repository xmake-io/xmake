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
-- @file        gcc_ar.lua
--

inherit("ar")

-- make the link arguments list
-- @see https://github.com/xmake-io/xmake/issues/5051
-- @note gcc-ar.exe does not support `gcc-ar.exe @file`
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    local argv = table.join(flags, targetfile, objectfiles)
    return self:program(), argv
end

-- link the library file
function link(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    os.mkdir(path.directory(targetfile))

    -- @note remove the previous archived file first to force recreating a new file
    os.tryrm(targetfile)

    -- link it
    local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    os.runv(program, argv, {envs = self:runenvs(), shell = opt.shell})
end


