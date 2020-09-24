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

-- do sign
function main(target, filepath, mode)

    -- get signtool
    local signtool = _get_tool(target, "signtool")

    -- get timestamp
    local timestamp = target:values("wdk.sign.timestamp") or "http://timestamp.verisign.com/scripts/timestamp.dll"

    -- init arguments
    local argv = {"sign", "/v", "/t", timestamp}
    local company = target:values("wdk.sign.company")
    if company then
        table.insert(argv, "/n")
        table.insert(argv, company)
    end
    local certfile = target:values("wdk.sign.certfile")
    if certfile then
        table.insert(argv, "/ac")
        table.insert(argv, certfile)
    end
    local thumbprint = target:values("wdk.sign.thumbprint")
    if thumbprint then
        table.insert(argv, "/sha1")
        table.insert(argv, thumbprint)
    end
    local store = target:values("wdk.sign.store")
    if not store and mode == "test" then
    end
    if store then
        table.insert(argv, "/a")
        table.insert(argv, "/s")
        table.insert(argv, store)
    end

    -- uses the default test certificate
    if mode == "test" and (not certfile and not thumbprint and not store) then
        table.insert(argv, "/a")
        table.insert(argv, "/n")
        table.insert(argv, "tboox.org(test)")
        table.insert(argv, "/s")
        table.insert(argv, "PrivateCertStore")
    end

    -- add target file
    table.insert(argv, filepath)

    -- do sign
    os.vrunv(signtool, argv)
end
