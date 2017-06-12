--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        target.lua
--

-- define module
local target = target or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local option    = require("project/option")
local config    = require("project/config")
local linker    = require("tool/linker")
local compiler  = require("tool/compiler")
local platform  = require("platform/platform")
local language  = require("language/language")

-- get the filename from the given target name and kind
function target.filename(targetname, targetkind, targetformat)

    -- check
    assert(targetname and targetkind)

    -- get format
    local format = targetformat or platform.format(targetkind) or {"", ""}

    -- make it
    return format[1] .. targetname .. format[2]
end

-- new a target instance
function target.new(name, info)

    -- init a target instance
    local instance = table.inherit(target)
    assert(instance)

    -- save name and info
    instance._NAME = name
    instance._INFO = info

    -- ok?
    return instance
end

-- get the target info
function target:get(name)
    return self._INFO[name]
end

-- add the value to the target info
function target:add(name_or_info, ...)
    if type(name_or_info) == "string" then
        self._INFO[name_or_info] = table.unique(table.join2(table.wrap(self._INFO[name_or_info]), ...))
    elseif type(name_or_info) == "table" and #name_or_info == 0 then
        for name, info in pairs(name_or_info) do
            self:add(name, info)
        end
    end
end

-- get the target name
function target:name()
    return self._NAME
end

-- get the base name of target file
function target:basename()
    return self:get("basename")
end

-- get the target linker
function target:linker()

    -- get it from cache first
    if self._LINKER then
        return self._LINKER
    end

    -- get the linker instance
    local instance, errors = linker.load(self:targetkind(), self:sourcekinds())
    if not instance then
        os.raise(errors)
    end

    -- cache it
    self._LINKER = instance

    -- get it
    return instance
end

-- make linking command for this target 
function target:linkcmd(objectfiles)
 
    -- make command
    return self:linker():linkcmd(objectfiles or self:objectfiles(), self:targetfile(), self)
end

-- make link flags for the given target
function target:linkflags()
 
    -- make flags
    return self:linker():linkflags(self)
end

-- get target deps
function target:deps()
    return self._DEPS
end

-- is phony target?
function target:isphony()
    
    -- get target kind
    local targetkind = self:targetkind()

    -- is phony?
    return not targetkind or targetkind == "phony"
end

-- get the options 
function target:options()

    -- attempt to get it from cache first
    if self._OPTIONS then
        return self._OPTIONS
    end

    -- load options 
    self._OPTIONS = {}
    for _, name in ipairs(table.wrap(self:get("options"))) do

        -- get option if be enabled
        local opt = nil
        if config.get(name) then opt = option.load(name) end
        if nil ~= opt then

            -- insert it and must ensure the order for linking
            table.insert(self._OPTIONS, opt)
        end
    end

    -- get it 
    return self._OPTIONS
end

-- get the object file directory
function target:objectdir()

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

-- get the target kind
function target:targetkind()

    -- get it
    return self:get("kind")
end

-- get the target file 
function target:targetfile()

    -- check
    assert(self)

    -- the target directory
    local targetdir = self:get("targetdir") or config.get("buildir")
    assert(targetdir and type(targetdir) == "string")

    -- get target kind
    local targetkind = self:targetkind()

    -- make the target file name and attempt to use the format of linker first
    local filename = target.filename(self:basename() or self:name(), targetkind, self:linker():format(targetkind))
    assert(filename)

    -- make the target file path
    return path.join(targetdir, filename)
end

-- get the symbol file
function target:symbolfile()

    -- check
    assert(self)

    -- the target directory
    local targetdir = self:get("targetdir") or config.get("buildir")
    assert(targetdir and type(targetdir) == "string")

    -- the symbol file name
    local filename = target.filename(self:basename() or self:name(), "symbol")
    assert(filename)

    -- make the symbol file path
    return path.join(targetdir, filename)
end

-- get the script directory of xmake.lua
function target:scriptdir()
    return self:get("__scriptdir")
end

-- get header directory
function target:headerdir()
    return self:get("headerdir") or config.get("buildir")
end

-- get the config header files
function target:configheader(outputdir)

    -- get config header
    local configheader = self:get("config_h")
    if not configheader then
        return 
    end

    -- get the root directory
    local rootdir, count = configheader:gsub("|.*$", ""):gsub("%(.*%)$", "")
    if count == 0 then
        rootdir = nil
    end

    -- remove '(' and ')'
    configheader = configheader:gsub("[%(%)]", "")

    -- get the output header
    local outputheader = nil
    if outputdir then
        if rootdir then
            outputheader = path.absolute(path.relative(configheader, rootdir), outputdir)
        else
            outputheader = path.join(outputdir, path.filename(configheader))
        end
    end

    -- ok
    return configheader, outputheader
end

-- get the source files 
function target:sourcefiles()

    -- check
    assert(self)

    -- cached? return it directly
    if self._SOURCEFILES then
        return self._SOURCEFILES, false
    end

    -- get files
    local files = self:get("files")

    -- no files?
    if not files then
        return {}, false
    end

    -- the patterns
    local patterns = 
    {
        {"([%w%*]+)%.obj|",     "%1|",  "object"}
    ,   {"([%w%*]+)%.obj$",     "%1",   "object"}
    ,   {"([%w%*]+)%.o|",       "%1|",  "object"}
    ,   {"([%w%*]+)%.o$",       "%1",   "object"}
    ,   {"([%w%*]+)%.lib|",     "%1|",  "static"}
    ,   {"([%w%*]+)%.lib$",     "%1",   "static"}
    ,   {"lib([%w%*]+)%.a|",    "%1|",  "static"}
    ,   {"lib([%w%*]+)%.a$",    "%1",   "static"}
    }

    -- match files
    local i = 1
    local count = 0
    local cache = true
    local sourcefiles = {}
    for _, file in ipairs(table.wrap(files)) do

        -- normalize *.[o|obj] and [lib]*.[a|lib] filename
        for _, pattern in ipairs(patterns) do
            file, count = file:gsub(pattern[1], target.filename(pattern[2], pattern[3]))
            if count > 0 then
                -- disable cache because the object and library files will be modified if them depend on previous target file
                cache = false
            end
        end

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

    -- cache it
    if cache then
        self._SOURCEFILES = sourcefiles
    end

    -- ok? modified?
    return sourcefiles, not cache
end

-- get object file from source file
function target:objectfile(sourcefile)

    -- translate: [lib]xxx*.[a|lib] => xxx/*.[o|obj] object file
    sourcefile = sourcefile:gsub(target.filename("([%w_]+)", "static"):gsub("%.", "%%.") .. "$", "%1/*")

    -- get the object directory
    local objectdir = self:objectdir()
    assert(objectdir and type(objectdir) == "string")

    -- make object file
    -- full file name(not base) to avoid name-clash of object file
    local objectfile = string.format("%s/%s/%s/%s", objectdir, self:name(), path.directory(sourcefile), target.filename(path.filename(sourcefile), "object"))

    -- translate path
    --
    -- .e.g 
    --
    -- src/xxx.c
    --      project/xmake.lua
    --          build/.objs
    --
    -- objectfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    --
    -- we need replace '..' to '__' in this case
    --
    objectfile = (path.translate(objectfile):gsub("%.%.", "__"))

    -- ok?
    return objectfile
end

-- get the object files
function target:objectfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._OBJECTFILES and not modified then
        return self._OBJECTFILES
    end

    -- get object files from source batches
    local objectfiles = {}
    for sourcekind, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(objectfiles, sourcebatch.objectfiles)
    end

    -- cache it
    self._OBJECTFILES = objectfiles

    -- ok?
    return objectfiles
end

-- get the header files
function target:headerfiles(outputdir)

    -- cached? return it directly
    if self._HEADERFILES and outputdir == nil then
        return self._HEADERFILES[1], self._HEADERFILES[2]
    end

    -- no headers?
    local headers = self:get("headers")
    if not headers then return end

    -- get the headerdir
    local headerdir = outputdir or self:headerdir()
    assert(headerdir)

    -- get the source pathes and destinate pathes
    local srcheaders = {}
    local dstheaders = {}
    for _, header in ipairs(table.wrap(headers)) do

        -- get the root directory
        local rootdir, count = header:gsub("|.*$", ""):gsub("%(.*%)$", "")
        if count == 0 then
            rootdir = nil
        end

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

                    -- the destinate header
                    local dstheader = nil
                    if rootdir then
                        dstheader = path.absolute(path.relative(srcpath, rootdir), headerdir)
                    else
                        dstheader = path.join(headerdir, path.filename(srcpath))
                    end
                    assert(dstheader)

                    -- add it
                    table.insert(dstheaders, dstheader)
                end
            end
        end
    end

    -- cache it
    if outputdir == nil then
        self._HEADERFILES = {srcheaders, dstheaders}
    end

    -- ok?
    return srcheaders, dstheaders
end

-- get incdep file from object file
function target:incdepfile(objectfile)
    return path.join(path.directory(objectfile), path.basename(objectfile) .. ".d")
end

-- get the dependent include files
function target:incdepfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._INCDEPFILES and not modified then
        return self._INCDEPFILES
    end

    -- get incdep files from source batches
    local incdepfiles = {}
    for sourcekind, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(incdepfiles, sourcebatch.incdepfiles)
    end

    -- cache it
    self._INCDEPFILES = incdepfiles

    -- ok?
    return incdepfiles
end

-- get the kinds of sourcefiles
--
-- .e.g cc cxx mm mxx as ...
--
function target:sourcekinds()

    -- cached? return it directly
    if self._SOURCEKINDS then
        return self._SOURCEKINDS
    end

    -- make source kinds
    local sourcekinds = {}
    for _, sourcefile in pairs(self:sourcefiles()) do

        -- get source kind
        local sourcekind = language.sourcekind_of(sourcefile)
        if sourcekind then
            table.insert(sourcekinds, sourcekind)
        end
    end

    -- remove repeat
    sourcekinds = table.unique(sourcekinds)

    -- cache it
    self._SOURCEKINDS = sourcekinds

    -- ok?
    return sourcekinds 
end

-- get source count
function target:sourcecount()
    return #self:sourcefiles()
end

-- get source batches
function target:sourcebatches()

    -- get source files
    local sourcefiles, modified = self:sourcefiles()

    -- cached? return it directly
    if self._SOURCEBATCHES and not modified then
        return self._SOURCEBATCHES, false
    end

    -- the extensional source kinds
    local sourcekinds_ext = 
    {
        [".o"]   = "obj"
    ,   [".obj"] = "obj"
    ,   [".a"]   = "lib"
    ,   [".lib"] = "lib"
    }

    -- make source batches for each source kinds
    local sourcebatches = {}
    for _, sourcefile in ipairs(sourcefiles) do

        -- get source kind
        local sourcekind = language.sourcekind_of(sourcefile)
        if not sourcekind then
            local sourcekind_ext = sourcekinds_ext[path.extension(sourcefile):lower()]
            if sourcekind_ext then
                sourcekind = sourcekind_ext
            end
        end

        -- unknown source kind
        if not sourcekind then
            os.raise("unknown source file: %s", sourcefile)
        end

        -- make this batch
        local sourcebatch = sourcebatches[sourcekind] or {sourcefiles = {}}
        sourcebatches[sourcekind] = sourcebatch

        -- add source kind to this batch
        sourcebatch.sourcekind = sourcekind

        -- add source file to this batch
        table.insert(sourcebatch.sourcefiles, sourcefile)
    end

    -- insert object files to source batches
    for sourcekind, sourcebatch in pairs(sourcebatches) do

        -- this batch support to compile multiple objects at the same time?
        local instance = compiler.load(sourcekind)
        if instance and instance:feature("object:sources") then

            -- get the first source file
            local sourcefile = sourcebatch.sourcefiles[1]

            -- insert single object file for all source files
            sourcebatch.objectfiles = self:objectfile(path.join(path.directory(sourcefile), "__" .. sourcekind))

            -- insert single incdep file for all source files
            sourcebatch.incdepfiles = self:incdepfile(sourcebatch.objectfiles)

        else

            -- insert object files for each source files
            sourcebatch.objectfiles = {}
            sourcebatch.incdepfiles = {}
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do

                -- get object file from this source file
                local objectfile = self:objectfile(sourcefile)

                -- add object file to this batch
                table.insert(sourcebatch.objectfiles, objectfile)

                -- add incdep file to this batch
                table.insert(sourcebatch.incdepfiles, self:incdepfile(objectfile))
            end
        end
    end

    -- cache it
    self._SOURCEBATCHES = sourcebatches

    -- ok?
    return sourcebatches, modified
end

-- get xxx_script
function target:script(name, generic)

    -- get script
    local script = self:get(name)
    if type(script) == "function" then
        return script
    elseif type(script) == "table" then

        -- match script for special plat and arch
        local plat = (config.get("plat") or "")
        local pattern = plat .. '|' .. (config.get("arch") or "")
        for _pattern, _script in pairs(script) do
            if not _pattern:startswith("__") and pattern:find('^' .. _pattern .. '$') then
                return _script
            end
        end

        -- match script for special plat
        for _pattern, _script in pairs(script) do
            if not _pattern:startswith("__") and plat:find('^' .. _pattern .. '$') then
                return _script
            end
        end

        -- get generic script
        return script["__generic__"] or generic
    end

    -- only generic script
    return generic
end

-- return module
return target
