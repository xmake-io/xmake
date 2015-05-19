--!The Automatic Crmakefiles-platform Build Tool
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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        makefile.lua
--

-- define module: makefile
local makefile = makefile or {}

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local platform  = require("platform/platform")

-- make the given target to the makefile
function makefile._make_target(file, name, target)

    -- check
    assert(file and name and target)

    -- make head
    file:write(string.format("%s:", name))

    -- make dependence for target
    if target.deps then
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            file:write(" " .. dep)
        end
    end

    -- make dependence for object
    local srcfiles = os.match(target.files)
    for _, srcfile in ipairs(srcfiles) do
        file:write(" " .. srcfile)
    end

    -- make dependence end
    file:write("\n")

    -- make body
    file:write(string.format("\techo \"%s\"\n", name))

    -- make end
    file:write("\n")

    -- ok
    return true
end

-- make all targets to the makefile
function makefile._make_targets(file)

    -- check 
    assert(file and project and project._CONFIGS)

    -- get all project targets
    local targets = project._CONFIGS._TARGET
    if not targets then
        -- error
        utils.error("not found target in this project!")
        return false
    end

    -- make all first
    local all = ""
    for name, _ in pairs(targets) do
        -- append the target name to all
        all = all .. " " .. name
    end
    file:write(string.format("all: %s\n\n", all))

    -- make it for all targets
    for name, target in pairs(targets) do
        -- make target
        if not makefile._make_target(file, name, target) then
            -- error
            utils.error("failed to make target %s to makefile!", name)
            return false
        end

        -- append the target name to all
        all = all .. " " .. name
    end
   
    -- ok
    return true
end

-- make makefile in the build directory
function makefile.make()

    -- the configs
    local configs = config._CONFIGS
    assert(configs and configs.buildir)

    -- make the build directory
    if not os.isdir(configs.buildir) then
        assert(os.mkdir(configs.buildir))
    end

    -- open the makefile 
    local path = configs.buildir .. "/makefile"
    local file = io.open(path, "w")
    if not file then
        -- error
        utils.error("open %s failed!", path)
        return false
    end

    -- make all targets to the makefile
    if not makefile._make_targets(file) then
        -- error 
        utils.error("save %s failed!", path)
        file:close()
        return false
    end

    -- close the makefile
    file:close()

    -- ok
    return true
end

-- build target
function makefile.build(target)

    -- check
    assert(target and type(target) == "string")

    -- the configs
    local configs = config._CONFIGS
    assert(configs and configs.buildir)

    -- done build
    local ok = os.execute(string.format("make -f %s %s", configs.buildir .. "/makefile", target))
    if ok ~= 0 then
        -- error
        utils.error("build target: %s failed!", target)
        return false
    end

    -- ok
    return true
end

-- return module: makefile
return makefile
