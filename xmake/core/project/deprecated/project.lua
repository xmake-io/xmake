--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        deprecated_project.lua
--

-- define module: deprecated_project
local deprecated_project = deprecated_project or {}

-- load modules
local os                        = require("base/os")
local path                      = require("base/path")
local utils                     = require("base/utils")
local table                     = require("base/table")
local config                    = require("project/config")
local platform                  = require("platform/platform")
local deprecated_interpreter    = require("base/deprecated/interpreter")

-- the current os is belong to the given os?
function deprecated_project._api_is_os(interp, ...)

    -- get the current os
    local os = platform.os()
    if not os then return false end

    -- exists this os?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and o == os then
            return true
        end
    end
end

-- the current mode is belong to the given modes?
function deprecated_project._api_is_mode(interp, ...)

    -- get the current mode
    local mode = config.get("mode")
    if not mode then return false end

    -- exists this mode?
    for _, m in ipairs(table.join(...)) do
        if m and type(m) == "string" and m == mode then
            return true
        end
    end
end

-- the current platform is belong to the given platforms?
function deprecated_project._api_is_plat(interp, ...)

    -- get the current platform
    local plat = config.get("plat")
    if not plat then return false end

    -- exists this platform? and escape '-'
    for _, p in ipairs(table.join(...)) do
        if p and type(p) == "string" and plat:find(p:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function deprecated_project._api_is_arch(interp, ...)

    -- get the current architecture
    local arch = config.get("arch")
    if not arch then return false end

    -- exists this architecture? and escape '-'
    for _, a in ipairs(table.join(...)) do
        if a and type(a) == "string" and arch:find(a:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current kind is belong to the given kinds?
function deprecated_project._api_is_kind(interp, ...)

    -- get the current kind
    local kind = config.get("kind")
    if not kind then return false end

    -- exists this kind?
    for _, k in ipairs(table.join(...)) do
        if k and type(k) == "string" and k == kind then
            return true
        end
    end
end

-- enable options?
function deprecated_project._api_is_option(interp, ...)

    -- some options are enabled?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and config.get(o) then
            return true
        end
    end
end

-- the current os is belong to the given os?
function deprecated_project._api_os(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_os(\"%s\"), \"os()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_os(interp, ...)
end

-- the current mode is belong to the given modes?
function deprecated_project._api_modes(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_mode(\"%s\"), \"modes()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_mode(interp, ...)
end

-- the current platform is belong to the given platforms?
function deprecated_project._api_plats(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_plat(\"%s\"), \"plats()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_plat(interp, ...)
end

-- the current platform is belong to the given architectures?
function deprecated_project._api_archs(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_arch(\"%s\"), \"archs()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_arch(interp, ...)
end

-- the current kind is belong to the given kinds?
function deprecated_project._api_kinds(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_kind(\"%s\"), \"kinds()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_kind(interp, ...)
end

-- enable options?
function deprecated_project._api_options(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_option(\"%s\"), \"options()\" has been deprecated!", values)

    -- done
    return deprecated_project._api_is_option(interp, ...)
end

-- register api
function deprecated_project.api_register(interp)

    -- register api: set_target() and set_option()
    deprecated_interpreter.api_register_set_scope(interp, "target", "option")
    deprecated_interpreter.api_register_add_scope(interp, "target", "option")
   
    -- register api: set_runscript() and set_installscript() and set_packagescript()
    deprecated_interpreter.api_register_set_script(interp, "target", nil,           "runscript"
                                                                                ,   "installscript"
                                                                                ,   "packagescript")

    -- register api: os(), kinds(), modes(), plats(), archs(), options()
    interp:api_register("os",       deprecated_project._api_os)
    interp:api_register("kinds",    deprecated_project._api_kinds)
    interp:api_register("modes",    deprecated_project._api_modes)
    interp:api_register("plats",    deprecated_project._api_plats)
    interp:api_register("archs",    deprecated_project._api_archs)
    interp:api_register("options",  deprecated_project._api_options)

end

-- return module: deprecated_project
return deprecated_project
