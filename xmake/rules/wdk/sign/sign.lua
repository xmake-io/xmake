--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        sign.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- get tool
function _get_tool(target, name)

    -- init cache
    _g.tools = _g.tools or {}

    -- get it from the cache
    local tool = _g.tools[name]
    if not tool then

        -- get wdk
        local wdk = target:data("wdk")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

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

-- get thumbprint
function _get_thumbprint(target)

    -- get it from the cache
    local thumbprint = _g.thumbprint
    if not thumbprint then

        -- try to get certificate info
        local certinfo = try 
        {
            function ()
                return os.iorun("certutil -store -user my")
            end
        }
        assert(certinfo, "cannot get certificate info in local machine!")

        -- trace certificate info
        if option.get("verbose") then
            print(certinfo)
        end

        -- get thumbprint from certificate info
        thumbprint = (certinfo:match("sha1.-: (%w+)") or ""):trim()
        assert(#thumbprint > 0, "cannot get thumbprint of certificate!")
        _g.thumbprint = thumbprint
    end
    return thumbprint
end

-- do test sign
function _sign_test(target, filepath)

    -- get signtool
    local signtool = _get_tool(target, "signtool")

    -- get makecert
    local makecert = _get_tool(target, "makecert")

    -- get certmgr
    local certmgr = _get_tool(target, "certmgr")

    -- get a test certificate
    local testcer = path.join(global.directory(), "sign", "test.cer")
    local company = "tboox.org(test)"
    local timestamp = target:values("wdk.sign.timestamp") or "http://timestamp.verisign.com/scripts/timestamp.dll"
    if not os.isfile(testcer) then

        -- make a new test certificate
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

        -- TODO enable test signing
        -- bcdedit.exe /set TESTSIGNING [ON|OFF]
    end

    -- do sign
    os.vrunv(signtool, {"sign", "/a", "/v", "/s", "PrivateCertStore", "/n", company, "/t", timestamp, filepath})
end

-- do release sign
function _sign_release(target, filepath)

    -- get signtool
    local signtool = _get_tool(target, "signtool")

    -- get *.cer file
    local cerfile = target:values("wdk.sign.cerfile") 
    assert(cerfile, "please call set_values(\"wdk.sign.cerfile\", ...) to set *.cer file for release signing!")

    -- get company
    local company = target:values("wdk.sign.company") 
    assert(company, "please call set_values(\"wdk.sign.company\", ...) to set company for release signing!")

    -- get timestamp
    local timestamp = target:values("wdk.sign.timestamp") or "http://timestamp.verisign.com/scripts/timestamp.dll"

    -- do sign
    os.vrunv(signtool, {"sign", "/v", "/ac", cerfile, "/n", company, "/t", timestamp, filepath})
end

-- do sign
function main(target, filepath, mode)

    -- sign is disabled?
    local enabled = target:values("wdk.sign.enabled")
    if enabled == false then
        return 
    end

    -- do sign
    if mode == "test" then
        _sign_test(target, filepath)
    else 
        _sign_release(target, filepath)
    end
end
