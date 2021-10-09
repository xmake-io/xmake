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
-- @file        run.lua
--

-- imports
import("core.base.option")
import("devel.debugger")
import("private.action.run.make_runenvs")

-- run on macosx
function _run_on_macosx(target, opt)

    -- get the runable target file
    local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
    local binarydir = path.join(contentsdir, "MacOS")
    local targetfile = path.join(binarydir, path.filename(target:targetfile()))

    -- get the run directory of target
    local rundir = target:rundir()

    -- enter the run directory
    local oldir = os.cd(rundir)

    -- add run environments
    local addrunenvs, setrunenvs = make_runenvs(target)
    for name, values in pairs(addrunenvs) do
        os.addenv(name, table.unpack(table.wrap(values)))
    end
    for name, value in pairs(setrunenvs) do
        os.setenv(name, table.unpack(table.wrap(value)))
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

-- run on simulator
function _run_on_simulator(target, opt)

    -- get devices list
    local list = try { function () return os.iorun("xcrun simctl list") end}
    assert(list, "simulator devices not found!")

    -- find the booted devices
    local name, deviceid
    for _, line in ipairs(list:split('\n', {plain = true})) do
        if line:find("(Booted)", 1, true) then
            line = line:trim()
            name, deviceid = line:match("(.-)%s+%(([%w%-]+)%)")
            if name and deviceid then
                break
            end
        end
    end
    assert(name and deviceid, "booted simulator devices not found!")

    -- do launch on first simulator device
    local bundle_identifier = target:values("xcode.bundle_identifier") or get_config("xcode_bundle_identifier") or "io.xmake." .. target:name()
    if bundle_identifier then
        print("running %s application on %s (%s) ..", target:name(), name, deviceid)
        os.execv("xcrun", {"simctl", "launch", "--console", deviceid, bundle_identifier})
    end
end

-- main entry
function main (target, opt)
    if target:is_plat("macosx") then
        _run_on_macosx(target, opt)
    elseif target:is_plat("iphoneos") and target:is_arch("x86_64", "i386") then
        _run_on_simulator(target, opt)
    else
        raise("we can only run application on macOS or simulator!")
    end
end


