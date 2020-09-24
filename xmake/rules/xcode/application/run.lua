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
-- @file        run.lua
--

-- imports
import("core.base.option")
import("devel.debugger")
import("private.action.run.make_runenvs")

-- main entry
function main (target, opt)

    -- get the runable target file
    local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
    local binarydir = contentsdir
    if is_plat("macosx") then
        binarydir = path.join(contentsdir, "MacOS")
    else
        raise("we can only run macOS application!")
    end
    local targetfile = path.join(binarydir, path.filename(target:targetfile()))

    -- get the run directory of target
    local rundir = target:rundir()

    -- enter the run directory
    local oldir = os.cd(rundir)

    -- add run environments
    local addrunenvs, setrunenvs = make_runenvs(target)
    for name, values in pairs(addrunenvs) do
        os.addenv(name, unpack(table.wrap(values)))
    end
    for name, value in pairs(setrunenvs) do
        os.setenv(name, unpack(table.wrap(value)))
    end

    -- debugging?
    if option.get("debug") then
        debugger.run(targetfile, option.get("arguments"))
    else
        os.execv(targetfile, option.get("arguments"))
    end

    -- restore the previous directory
    os.cd(oldir)
end


