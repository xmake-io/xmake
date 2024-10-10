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
-- @file        xmake.lua
--

-- add envs for `xrepo env`
-- @see https://github.com/xmake-io/xmake/issues/5580
--
-- @code
-- includes("@builtin/xrepo")
--
-- xrepo_addenvs(function (package)
--     package:addenv("FOO", "FOO")
-- end)
--
-- xrepo_addenvs({BAR = "BAR"})
-- @endcode
--
function xrepo_addenvs(envs)
    local packagename = "__xrepo_addenvs_" .. hash.strhash32(tostring(envs))
    package(packagename)
        on_load(function (package)
            if type(envs) == "function" then
                envs(package)
            elseif type(envs) == "table" then
                for k, v in pairs(envs) do
                    package:addenv(k, v)
                end
            end
        end)
        on_fetch(function (package, opt)
            return {}
        end)
    package_end()
    add_requires(packagename)
end

-- add env for `xrepo env`
-- @see https://github.com/xmake-io/xmake/issues/5580
--
-- @code
-- includes("@builtin/xrepo")
--
-- xrepo_addenv("ZOO", ...)
-- @endcode
--
function xrepo_addenv(name, ...)
    local args = table.pack(...)
    local packagename = "__xrepo_addenv_" .. name .. hash.strhash32(table.concat(args))
    package(packagename)
        on_load(function (package)
            package:addenv(name, table.unpack(args))
        end)
        on_fetch(function (package, opt)
            return {}
        end)
    package_end()
    add_requires(packagename)
end
