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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        rule.lua
--

-- define module: rule
local rule = rule or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("base/platform")

-- get the building log file path
function rule.logfile()

    -- the logdir
    local logdir = config.get("buildir") or os.tmpdir()
    assert(logdir)

    -- get it
    return path.translate(logdir .. "/.build.log")
end

-- get the filename from the given name and kind
function rule.filename(name, kind)

    -- check
    assert(name and kind)

    -- get format
    local format = platform.format(kind) or {"", ""}

    -- make it
    return format[1] .. name .. format[2]
end

-- get the makefile path
function rule.makefile()

    -- get the build directory
    local buildir = config.get("buildir")
    assert(buildir)

    -- get it
    return path.translate(buildir .. "/makefile")
end

-- get configure file for the given target
function rule.config_h(target)
 
    -- get the target configure file 
    local config_h = target.config_h
    if config_h then 
        -- translate file path
        if not path.is_absolute(config_h) then
            config_h = path.absolute(config_h, xmake._PROJECT_DIR)
        else
            config_h = path.translate(config_h)
        end
    end
     
    -- ok?
    return config_h
end

-- get the temporary backup directory for package
function rule.backupdir(target_name, arch)

    -- the temporary directory
    local tmpdir = os.tmpdir()
    assert(tmpdir)

    -- the project name
    local project_name = path.basename(xmake._PROJECT_DIR)
    assert(project_name)

    -- make it
    return string.format("%s/.xmake/%s/pkgfiles/%s/%s", tmpdir, project_name, target_name, arch)
end

-- get target file for the given target
function rule.targetfile(target_name, target, buildir)

    -- check
    assert(target_name and target and target.kind)

    -- the target directory
    local targetdir = target.targetdir or buildir or config.get("buildir")
    assert(targetdir and type(targetdir) == "string")

    -- the target file name
    local filename = rule.filename(target_name, target.kind)
    assert(filename)

    -- make the target file path
    return targetdir .. "/" .. filename
end

-- get object files for the given source files
function rule.objectdir(target_name, target, buildir)

    -- check
    assert(target_name and target)

    -- the object directory
    local objectdir = target.objectdir
    if not objectdir then

        -- the build directory
        if not buildir then
            buildir = config.get("buildir")
        end
        assert(buildir)
   
        -- make the default object directory
        objectdir = buildir .. "/.objs"
    end
  
    -- ok?
    return objectdir
end

-- get object files for the given source files
function rule.objectfiles(target_name, target, sourcefiles, buildir)

    -- check
    assert(target_name and target and sourcefiles)

    -- the object directory
    local objectdir = rule.objectdir(target_name, target, buildir)
    assert(objectdir and type(objectdir) == "string")
   
    -- make object files
    local i = 1
    local objectfiles = {}
    for _, sourcefile in ipairs(sourcefiles) do

        -- translate: [lib]xxx*.[a|lib] => xxx/*.[o|obj] object file
        sourcefile = sourcefile:gsub(rule.filename("(%w+)", "static"):gsub("%.", "%%.") .. "$", "%1/*")

        -- make object file
        local objectfile = string.format("%s/%s/%s/%s", objectdir, target_name, path.directory(sourcefile), rule.filename(path.basename(sourcefile), "object"))

        -- translate path
        --
        -- .e.g 
        --
        -- src/xxx.c
        --     project/xmake.lua
        --             build/.objs
        --
        -- objectfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
        --
        -- we need replace '..' to '__' in this case
        --
        objectfile = (path.translate(objectfile):gsub("%.%.", "__"))

        -- save it
        objectfiles[i] = objectfile
        i = i + 1

    end

    -- ok?
    return objectfiles
end

-- get the source files from the given target
function rule.sourcefiles(target)

    -- check
    assert(target)

    -- no files?
    if not target.files then
        return {}
    end

    -- wrap files first
    local targetfiles = utils.wrap(target.files)

    -- match files
    local i = 1
    local sourcefiles = {}
    for _, targetfile in ipairs(targetfiles) do

        -- normalize *.[o|obj] filename
        targetfile = targetfile:gsub("([%w%*]+)%.obj|", rule.filename("%1|", "object"))
        targetfile = targetfile:gsub("([%w%*]+)%.obj$", rule.filename("%1", "object"))
        targetfile = targetfile:gsub("([%w%*]+)%.o|", rule.filename("%1|", "object"))
        targetfile = targetfile:gsub("([%w%*]+)%.o$", rule.filename("%1", "object"))

        -- normalize [lib]*.[a|lib] filename
        targetfile = targetfile:gsub("([%w%*]+)%.lib|", rule.filename("%1|", "static"))
        targetfile = targetfile:gsub("([%w%*]+)%.lib$", rule.filename("%1", "static"))
        targetfile = targetfile:gsub("lib([%w%*]+)%.a|", rule.filename("%1|", "static"))
        targetfile = targetfile:gsub("lib([%w%*]+)%.a$", rule.filename("%1", "static"))

        -- match source files
        local files = os.match(targetfile)
        if #files == 0 then
            utils.warning("cannot match add_files(\"%s\")", targetfile)
        end

        -- process source files
        for _, file in ipairs(files) do

            -- convert to the relative path
            if path.is_absolute(file) then
                file = path.relative(file, xmake._PROJECT_DIR)
            end

            -- save it
            sourcefiles[i] = file
            i = i + 1

        end
    end

    -- remove repeat files
    sourcefiles = utils.unique(sourcefiles)

    -- ok?
    return sourcefiles
end

-- get the header files from the given target
function rule.headerfiles(target, headerdir)

    -- check
    assert(target)

    -- no headers?
    local headers = target.headers
    if not headers then return end

    -- get the headerdir
    if not headerdir then headerdir = target.headerdir or config.get("buildir") end
    assert(headerdir)

    -- get the source pathes and destinate pathes
    local srcheaders = {}
    local dstheaders = {}
    for _, header in ipairs(utils.wrap(headers)) do

        -- get the root directory
        local rootdir = header:gsub("%(.*%)", ""):gsub("|.*$", "")

        -- remove '(' and ')'
        local srcpathes = header:gsub("[%(%)]", "")
        if srcpathes then 

            -- get the source pathes
            srcpathes = os.match(srcpathes)
            if srcpathes then

                -- add the source headers
                table.join2(srcheaders, srcpathes)

                -- add the destinate headers
                for _, srcpath in ipairs(srcpathes) do

                    -- the header
                    local dstheader = path.absolute(path.relative(srcpath, rootdir), headerdir)
                    assert(dstheader)

                    -- add it
                    table.insert(dstheaders, dstheader)
                end
            end
        end
    end

    -- ok?
    return srcheaders, dstheaders
end

-- return module: rule
return rule
