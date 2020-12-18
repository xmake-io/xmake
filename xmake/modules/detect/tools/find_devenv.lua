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
-- @file        find_devenv.lua
--

-- imports
import("core.project.config")
import("core.tool.toolchain")

-- find devenv
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local devenv = find_devenv()
--
-- @endcode
--
function main(opt)

    -- not on windows?
    if not is_host("windows") then
        return
    end

    -- disable to check version
    opt         = opt or {}
    opt.command = function () end

    -- find it from %DevEnvdir%
    -- e.g. C:\Program Files\Microsoft Visual Studio 9.0\Common7\IDE
    --
    local program = nil
    local msvc = toolchain.load("msvc")
    if msvc then
        local vcvars = msvc:config("vcvars")
        if vcvars then
            if vcvars.DevEnvdir and os.isexec(path.join(vcvars.DevEnvdir, "devenv.exe")) then
                program = path.join(vcvars.DevEnvdir, "devenv.exe")
            end
        end
    end
    return program
end

