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
-- @file        testcert.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("detect.sdks.find_wdk")

-- get tool
function _get_tool(wdk, name)

    -- init cache
    _g.tools = _g.tools or {}

    -- get it from the cache
    local tool = _g.tools[name]
    if not tool then

        -- get arch
        local arch = config.arch() or os.arch()

        -- get tool
        tool = path.join(wdk.bindir, arch, name .. ".exe")
        if not os.isexec(tool) then
            tool = path.join(wdk.bindir, wdk.sdkver, arch, name .. ".exe")
        end
        assert(os.isexec(tool), name .. " not found!")
        _g.tools[name] = tool
    end
    return tool
end

-- install test certificate
function _install(wdk)

    -- get signtool
    local signtool = _get_tool(wdk, "signtool")

    -- check test certificate first
    local ok = try
    {
        function ()
            local tmpfile = os.tmpfile(os.programfile())
            if not os.isfile(tmpfile) then
                os.cp(os.programfile(), tmpfile)
            end
            os.vrunv(signtool, {"sign", "/v", "/a", "/s", "PrivateCertStore", "/n", "tboox.org(test)", tmpfile})
            return true
        end
    }
    if ok then
        return
    end

    -- get makecert
    local makecert = _get_tool(wdk, "makecert")

    -- get certmgr
    local certmgr = _get_tool(wdk, "certmgr")

    -- get a test certificate
    local testcer = path.join(global.directory(), "sign", "test.cer")
    local company = "tboox.org(test)"

    -- make a new test certificate @note need re-generate certificate when reinstalling
    local signdir = path.directory(testcer)
    if not os.isdir(signdir)  then
        os.mkdir(signdir)
    end
    os.vrunv(makecert, {"-r", "-pe", "-ss", "PrivateCertStore", "-n", "CN=" .. company, testcer})

    -- register this test certificate
    try
    {
        function ()
            os.vrunv(certmgr, {"/add", testcer, "/s", "/r", "localMachine", "root"})
            os.vrunv(certmgr, {"/add", testcer, "/s", "/r", "localMachine", "trustedpublisher"})
        end,
        catch
        {
            function (errors)
                os.tryrm(testcer)
                raise(errors)
            end
        }
    }

    -- trace
    print("install test certificate ok!")
    print("  - company: %s", company)
    print("  - cerfile: %s", testcer)
end

-- entry function
function main(action)

    -- find wdk envirnoment first
    local wdk = find_wdk()
    assert(wdk, "wdk not found!")

    -- install or uninstall test certificate
    if action == "install" then
        _install(wdk)
    end
end
