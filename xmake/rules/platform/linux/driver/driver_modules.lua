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
-- @file        driver_modules.lua
--

-- get linux-headers sdk
function _get_linux_headers_sdk(target)
    local linux_headers = assert(target:pkg("linux-headers"), "please add `add_requires(\"linux-headers\", {configs = {driver_modules = true}})` and `add_packages(\"linux-headers\")` to the given target!")
    local includedirs = linux_headers:get("includedirs") or linux_headers:get("sysincludedirs")
    local version = linux_headers:version()
    local linux_headersdir
    for _, includedir in ipairs(includedirs) do
        if includedir:find("linux-headers", 1, true) then
            linux_headersdir = path.directory(includedir)
            break
        end
    end
    assert(linux_headersdir, "linux-headers not found!")
    return {version = version, sdkdir = linux_headersdir, includedirs = includedirs}
end

function load(target)
    -- we need only need binary kind, because we will rewrite on_link
    target:set("kind", "binary")

    -- get and save linux-headers sdk
    local linux_headers = _get_linux_headers_sdk(target)
    target:data_set("linux.driver.linux_headers", linux_headers)
    print(linux_headers)
end

function link(target, opt)
end
