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
import("core.project.config")

-- get sign tool
function _get_signtool(target)

    -- get it from the cache
    local signtool = _g.signtool
    if not signtool then

        -- get wdk
        local wdk = target:data("wdk")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get signtool
        signtool = path.join(wdk.bindir, arch, "signtool.exe")
        if not os.isexec(signtool) then
            signtool = path.join(wdk.bindir, wdk.sdkver, arch, "signtool.exe")
        end
        assert(os.isexec(signtool), "signtool not found!")
        _g.signtool = signtool
    end
    return signtool
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

-- do sign
function main(target, filepath, mode)

    -- sign is disabled?
    local enabled = target:values("wdk.sign.enabled")
    if enabled == false then
        return 
    end

    -- get signtool
    local signtool = _get_signtool(target)

    -- get thumbprint
    local thumbprint = _get_thumbprint(target)

    -- sign the target file
    os.vrunv(signtool, {"sign", "/ph", "/sha1", thumbprint, filepath})
end
