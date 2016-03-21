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
-- @file        target.lua
--

-- define module
local target = target or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local option    = require("project/option")
local config    = require("project/config")
local linker    = require("platform/linker")
local platform  = require("platform/platform")

-- get the filename from the given name and kind
function target.filename(name, kind)

    -- check
    assert(name and kind)

    -- get format
    local format = platform.format(kind) or {"", ""}

    -- make it
    return format[1] .. name .. format[2]
end

-- get the target info
function target.get(self, infoname)

    -- check
    assert(self and self._INFO and infoname)

    -- get it
    return self._INFO[infoname]
end

-- get the target name
function target.name(self)

    -- get it
    return self._NAME
end

-- get the linker with the target kind
function target.linker(self)

    -- init the linker from the given kind
    local result = linker.init(self:get("kind"))
    if not result then 
        os.raise("cannot get linker with kind: %s", self:get("kind"))
    end

    -- ok?
    return result

end

-- get the options 
function target.options(self)

    -- the options
    local options = {}
    for _, name in ipairs(table.wrap(self:get("options"))) do

        -- get option if be enabled
        local opt = nil
        if config.get(name) then opt = poption.load(name) end
        if nil ~= opt then
            options[name] = opt
        end
    end

    -- ok?
    return options
end

-- get the object file directory
function target.objectdir(self)

    -- check
    assert(self)

    -- the object directory
    local objectdir = self:get("objectdir")
    if not objectdir then

        -- make the default object directory
        objectdir = path.join(config.get("buildir"), ".objs")
    end
  
    -- ok?
    return objectdir
end

-- get the target file 
function target.targetfile(self)

    -- check
    assert(self)

    -- the target directory
    local targetdir = self:get("targetdir") or config.get("buildir")
    assert(targetdir and type(targetdir) == "string")

    -- the target file name
    local filename = target.filename(self:name(), self:get("kind"))
    assert(filename)

    -- make the target file path
    return path.join(targetdir, filename)
end

-- get the source files 
function target.sourcefiles(self)

    -- check
    assert(self)

    -- get files
    local files = self:get("files")

    -- no files?
    if not files then
        return {}
    end

    -- match files
    local i = 1
    local sourcefiles = {}
    for _, file in ipairs(table.wrap(files)) do

        -- normalize *.[o|obj] filename
        file = file:gsub("([%w%*]+)%.obj|", target.filename("%1|", "object"))
        file = file:gsub("([%w%*]+)%.obj$", target.filename("%1", "object"))
        file = file:gsub("([%w%*]+)%.o|", target.filename("%1|", "object"))
        file = file:gsub("([%w%*]+)%.o$", target.filename("%1", "object"))

        -- normalize [lib]*.[a|lib] filename
        file = file:gsub("([%w%*]+)%.lib|", target.filename("%1|", "static"))
        file = file:gsub("([%w%*]+)%.lib$", target.filename("%1", "static"))
        file = file:gsub("lib([%w%*]+)%.a|", target.filename("%1|", "static"))
        file = file:gsub("lib([%w%*]+)%.a$", target.filename("%1", "static"))

        -- match source files
        local srcfiles = os.match(file)
        if #srcfiles == 0 then
            utils.warning("cannot match add_files(\"%s\")", file)
        end

        -- process source files
        for _, srcfile in ipairs(srcfiles) do

            -- convert to the relative path
            if path.is_absolute(srcfile) then
                srcfile = path.relative(srcfile, xmake._PROJECT_DIR)
            end

            -- save it
            sourcefiles[i] = srcfile
            i = i + 1

        end
    end

    -- remove repeat files
    sourcefiles = table.unique(sourcefiles)

    -- ok?
    return sourcefiles
end

-- get the object files
function target.objectfiles(self)

    -- check
    assert(self)

    -- get the object directory
    local objectdir = self:objectdir()
    assert(objectdir and type(objectdir) == "string")

    -- get the source files
    local sourcefiles = self:sourcefiles()
    assert(sourcefiles)
   
    -- make object files
    local i = 1
    local objectfiles = {}
    for _, sourcefile in ipairs(sourcefiles) do

        -- translate: [lib]xxx*.[a|lib] => xxx/*.[o|obj] object file
        sourcefile = sourcefile:gsub(target.filename("([%w_]+)", "static"):gsub("%.", "%%.") .. "$", "%1/*")

        -- make object file
        local objectfile = string.format("%s/%s/%s/%s", objectdir, self:name(), path.directory(sourcefile), target.filename(path.basename(sourcefile), "object"))

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

-- get the header files
function target.headerfiles(self)

    -- check
    assert(self)

    -- no headers?
    local headers = self:get("headers")
    if not headers then return end

    -- get the headerdir
    local headerdir = self:get("headerdir") or config.get("buildir")
    assert(headerdir)

    -- get the source pathes and destinate pathes
    local srcheaders = {}
    local dstheaders = {}
    for _, header in ipairs(table.wrap(headers)) do

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


-- return module
return target
