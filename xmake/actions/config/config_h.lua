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
-- @file        config_h.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- make configure for the given target name
function _make_for_target(files, targetname, target)

    -- get the target configure file 
    local config_h = target.config_h
    if not config_h then return end

    -- the prefix
    local prefix = target.config_h_prefix or (targetname:upper() .. "_CONFIG")

    -- open the file
    local file = files[config_h] or io.open(config_h, "w")

    -- make the head
    if files[config_h] then file:write("\n") end
    file:write(format("#ifndef %s_H\n", prefix))
    file:write(format("#define %s_H\n", prefix))
    file:write("\n")

    -- make version
    if target.version then
        file:write("// version\n")
        file:write(format("#define %s_VERSION \"%s\"\n", prefix, target.version))
        local i = 1
        local m = {"MAJOR", "MINOR", "ALTER"}
        for v in target.version:gmatch("%d+") do
            file:write(format("#define %s_VERSION_%s %s\n", prefix, m[i], v))
            i = i + 1
            if i > 3 then break end
        end
        file:write(format("#define %s_VERSION_BUILD %s\n", prefix, os.date("%Y%m%d%H%M", os.time())))
        file:write("\n")
    end

    -- make the defines
    local defines = table.copy(target.defines_h) 

    -- make the undefines
    local undefines = table.copy(target.undefines_h) 

    -- make the options
    for _, name in ipairs(utils.wrap(target.options)) do

        -- get option if be enabled
        local opt = nil
        if config.get(name) then opt = config.get("__" .. name) end
        if nil ~= opt then

            -- get the option defines
            table.join2(defines, opt.defines_h_if_ok) 

            -- get the option undefines
            table.join2(undefines, opt.undefines_h_if_ok) 

        end
    end

    -- make the defines
    if #defines ~= 0 then
        file:write("// defines\n")
        for _, define in ipairs(defines) do
            file:write(format("#define %s 1\n", define:gsub("=", " "):gsub("%$%((.-)%)", function (w) if w == "prefix" then return prefix end end)))
        end
        file:write("\n")
    end

    -- make the undefines 
    if #undefines ~= 0 then
        file:write("// undefines\n")
        for _, undefine in ipairs(undefines) do
            file:write(format("#undef %s\n", undefine:gsub("%$%((.-)%)", function (w) if w == "prefix" then return prefix end end)))
        end
        file:write("\n")
    end

    -- make the tail
    file:write("#endif\n")

    -- cache the file
    files[config_h] = file

end

-- make the configure file for the given target and dependents
function _make_for_target_with_deps(files, targetname)

    -- the target
    local target = project.target(targetname)

    -- make configure for the target
    _make_for_target(files, targetname, target)
     
    -- make configure for the dependent targets?
    for _, dep in ipairs(utils.wrap(target.deps)) do
        _make_for_target_with_deps(files, dep)
    end

end

-- make the config.h
function make()

    -- the target name
    local targetname = option.get("target")

    -- enter project directory
    os.cd(project.directory())

    -- init files
    local files = {}

    -- make configure for the given target name
    if targetname and targetname ~= "all" then
        _make_for_target_with_deps(files, targetname)
    else

        -- make configure for all targets
        for name, target in pairs(project.targets()) do
            _make_for_target(files, name, target)
        end
    end

    -- exit files
    for _, file in pairs(files) do
        file:close()
    end
 
    -- leave project directory
    os.cd("-")

end
