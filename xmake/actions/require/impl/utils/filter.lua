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
-- @file        filter.lua
--

-- imports
import("core.base.filter")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.project.project")
import("core.sandbox.sandbox")

-- get filter
function _filter()

    -- init filter
    if _g.filter == nil then
        _g.filter = filter.new()
        _g.filter:register("common", function (variable)

            -- attempt to get it directly from the configure
            local result = config.get(variable)
            if result == nil then

                -- init maps
                _g.common_maps = _g.common_maps or
                {
                    host        = os.host()
                ,   subhost     = os.subhost()
                ,   tmpdir      = function () return os.tmpdir() end
                ,   curdir      = function () return os.curdir() end
                ,   scriptdir   = function () return os.scriptdir() end
                ,   globaldir   = global.directory()
                ,   configdir   = config.directory()
                ,   projectdir  = project.directory()
                ,   programdir  = os.programdir()
                }

                -- map it
                result = _g.common_maps[variable]
            end

            -- is script? call it
            if type(result) == "function" then
                result = result()
            end

            -- ok?
            return result
        end)
    end

    -- ok
    return _g.filter
end

-- the package handler
function _handler(package, strval)

    -- @note cannot cache it, because the package instance will be changed
    return function (variable)

        -- init maps
        local maps =
        {
            version = function ()
                if strval then
                    -- set_urls("https://sqlite.org/2018/sqlite-autoconf-$(version)000.tar.gz",
                    --          {version = function (version) return version:gsub("%.", "") end})
                    local version_filter = package:url_version(strval)
                    if version_filter then
                        return version_filter(package:version_str())
                    end
                end
                return package:version_str()
            end
        }

        -- get value
        local result = maps[variable]
        if type(result) == "function" then
            result = result()
        end

        -- ok?
        return result
    end
end

-- attach filter to the given script and call it
function call(script, package)

    -- get sandbox filter and handlers of the given script
    local sandbox_filter   = sandbox.filter(script)
    local sandbox_handlers = sandbox_filter:handlers()

    -- switch to the handlers of the current filter
    sandbox_filter:set_handlers(_filter():handlers())

    -- register package handler
    sandbox_filter:register("package", _handler(package))

    -- call it
    script(package)

    -- restore handlers
    sandbox_filter:set_handlers(sandbox_handlers)
end

-- handle the string value of package
function handle(strval, package)

    -- register filter handler
    _filter():register("package", _handler(package, strval))

    -- handle string value
    strval = _filter():handle(strval)

    -- register filter handler
    _filter():register("package", nil)

    -- ok
    return strval
end

