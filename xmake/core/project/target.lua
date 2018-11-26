--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        target.lua
--

-- define module
local target = target or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local deprecated     = require("base/deprecated")
local rule           = require("project/rule")
local option         = require("project/option")
local config         = require("project/config")
local requireinfo    = require("project/requireinfo")
local tool           = require("tool/tool")
local linker         = require("tool/linker")
local compiler       = require("tool/compiler")
local platform       = require("platform/platform")
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- get target apis
function target.apis()

    return 
    {
        values =
        {
            -- target.set_xxx
            "target.set_kind"
        ,   "target.set_strip"
        ,   "target.set_rules"
        ,   "target.set_enabled"
        ,   "target.set_default"
        ,   "target.set_options"
        ,   "target.set_symbols"
        ,   "target.set_filename"
        ,   "target.set_basename"
        ,   "target.set_warnings"
        ,   "target.set_optimize"
        ,   "target.set_languages"
            -- target.add_xxx
        ,   "target.add_deps"
        ,   "target.add_rules"
        ,   "target.add_options"
        ,   "target.add_packages"
        ,   "target.add_imports"
        ,   "target.add_languages"
        ,   "target.add_vectorexts"
        }
    ,   keyvalues =
        {
            -- target.set_xxx
            "target.set_values"
            -- target.add_xxx
        ,   "target.add_values"
        }
    ,   pathes = 
        {
            -- target.set_xxx
            "target.set_targetdir"
        ,   "target.set_objectdir"
        ,   "target.set_dependir"
            -- target.add_xxx
        ,   "target.add_files"
            -- target.del_xxx
        ,   "target.del_files"
        }
    ,   dictionary =
        {
            -- target.set_xxx
            "target.set_tools"
        ,   "target.add_tools"
        }
    ,   script =
        {
            -- target.on_xxx
            "target.on_run"
        ,   "target.on_load"
        ,   "target.on_build"
        ,   "target.on_build_file"
        ,   "target.on_build_files"
        ,   "target.on_clean"
        ,   "target.on_package"
        ,   "target.on_install"
        ,   "target.on_uninstall"
            -- target.before_xxx
        ,   "target.before_run"
        ,   "target.before_build"
        ,   "target.before_build_file"
        ,   "target.before_build_files"
        ,   "target.before_clean"
        ,   "target.before_package"
        ,   "target.before_install"
        ,   "target.before_uninstall"
            -- target.after_xxx
        ,   "target.after_run"
        ,   "target.after_build"
        ,   "target.after_build_file"
        ,   "target.after_build_files"
        ,   "target.after_clean"
        ,   "target.after_package"
        ,   "target.after_install"
        ,   "target.after_uninstall"
        }
    }
end

-- get the filename from the given target name and kind
function target.filename(targetname, targetkind, targetformat)

    -- check
    assert(targetname and targetkind)

    -- make filename by format
    local format = targetformat or platform.format(targetkind) 
    return format and (format:gsub("%$%(name%)", targetname)) or targetname
end

-- get the link name of the target file
function target.linkname(filename)
    local linkname, count = filename:gsub(target.filename("__pattern__", "static"):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
    if count == 0 then
        linkname, count = filename:gsub(target.filename("__pattern__", "shared"):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
    end
    return count > 0 and linkname or nil
end

-- new a target instance
function target.new(name, info, project)

    -- init a target instance
    local instance = table.inherit(target)
    assert(instance)

    -- save name and info
    instance._NAME = name
    instance._INFO = info
    instance._PROJECT = project

    -- ok?
    return instance
end

-- load rule, move cache to target
function target:_load_rule(ruleinst, suffix)

    -- init cache
    local key = ruleinst:name() .. (suffix and ("_" .. suffix) or "")
    local cache = self._RULES_LOADED or {}

    -- do load
    if cache[key] == nil then
        local on_load = ruleinst:script("load" .. (suffix and ("_" .. suffix) or ""))
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            cache[key] = {ok, errors}
        else
            cache[key] = {true}
        end
    end

    -- save cache
    self._RULES_LOADED = cache

    -- return results
    local results = cache[key]
    if results then
        return results[1], results[2]
    end
end

-- load rules
function target:_load_rules(suffix)
    for _, r in pairs(self:orderules()) do
        local ok, errors = self:_load_rule(r, suffix)
        if not ok then
            return false, errors
        end
    end
    return true
end

-- do load target and rules
function target:_load()

    -- do before_load with target rules
    local ok, errors = self:_load_rules("before")
    if not ok then
        return false, errors
    end

    -- do load with target rules
    local ok, errors = self:_load_rules()
    if not ok then
        return false, errors
    end

    -- do load for target
    local on_load = self:script("load")
    if on_load then
        local ok, errors = sandbox.load(on_load, self)
        if not ok then
            return false, errors
        end
    end

    -- do after_load with target rules
    local ok, errors = self:_load_rules("after")
    if not ok then
        return false, errors
    end

    -- ok
    return true
end

-- get the target info
function target:get(name)
    return self._INFO[name]
end

-- set the value to the target info
function target:set(name_or_info, ...)

    -- set values to the given key?
    if type(name_or_info) == "string" then

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then 
            table.remove(values)
        else
            extra_config = nil
        end

        -- set values
        local name = name_or_info
        if #values > 0 then
            self._INFO[name] = table.unwrap(table.unique(table.join(unpack(values))))
        else
            self._INFO[name] = nil
        end

        -- save extra config
        if extra_config then
            self._INFO["__extra_" .. name] = self._INFO["__extra_" .. name] or {}
            local extrascope = self._INFO["__extra_" .. name]
            for _, value in ipairs(values) do
                extrascope[value] = extra_config
            end
        end

    -- set a dictionary values
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:set(name, info)
        end
    end
end

-- add the value to the target info
function target:add(name_or_info, ...)

    -- add values to the given key?
    if type(name_or_info) == "string" then

        -- get extra config
        local values = {...}
        local extra_config = values[#values]
        if table.is_dictionary(extra_config) then 
            table.remove(values)
        else
            extra_config = nil
        end

        -- add values
        local name = name_or_info
        local info = table.wrap(self._INFO[name])
        self._INFO[name] = table.unwrap(table.unique(table.join(info, unpack(values))))

        -- save extra config
        if extra_config then
            self._INFO["__extra_" .. name] = self._INFO["__extra_" .. name] or {}
            local extrascope = self._INFO["__extra_" .. name]
            for _, value in ipairs(values) do
                extrascope[value] = extra_config
            end
        end

    -- add a dictionary values
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:add(name, info)
        end
    end
end

-- get user private data
function target:data(name)
    return self._DATA and self._DATA[name] or nil
end

-- set user private data
function target:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function target:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
end

-- get values
function target:values(name, sourcefile)

    -- get values from the source file first
    local values = {}
    if sourcefile then
        local fileconfig = self:fileconfig(sourcefile)
        if fileconfig then
            local filevalues = fileconfig.values
            if filevalues then
                -- we use '_' to simplify setting, for example:
                --
                -- add_files("xxx.mof", {values = {wdk_mof_header = "xxx.h"}}) 
                -- add_files("xxx.mof", {values = {["wdk.mof.header"] = "xxx.h"}}) 
                --
                table.join2(values, filevalues[name] or filevalues[name:gsub("%.", "_")])
            end
        end
    end

    -- get values from target
    table.join2(values, self:get("values." .. name))
    return #values > 0 and table.unwrap(values) or nil
end

-- set values
function target:values_set(name, ...)
    self:set("values." .. name, ...)
end

-- add values
function target:values_add(name, ...)
    self:add("values." .. name, ...)
end

-- dump this target
function target:dump()
    table.dump(self._INFO)
end

-- get the type: option
function target:type()
    return "target"
end

-- get the target name
function target:name()
    return self._NAME
end

-- get the base name of target file
function target:basename()
    local filename = self:get("filename")
    if filename then
        return path.basename(filename)
    end
    return self:get("basename") or self:name()
end

-- get the target linker
function target:linker()

    -- get it from cache first
    if self._LINKER then
        return self._LINKER
    end

    -- get the linker instance
    local instance, errors = linker.load(self:targetkind(), self:sourcekinds(), self)
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
    return self:linker():linkcmd(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make linking arguments for this target 
function target:linkargv(objectfiles)
    return self:linker():linkargv(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make link flags for the given target
function target:linkflags()
    return self:linker():linkflags({target = self})
end

-- get the given dependent target
function target:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get target deps
function target:deps()
    return self._DEPS
end

-- get target order deps
function target:orderdeps()
    return self._ORDERDEPS
end

-- get the given dependent config
function target:depconfig(name)

    -- get deps config
    --
    -- .e.g {inherit = false}
    --
    local depsconfig = self._DEPSCONFIG
    if not depsconfig then
        depsconfig = {}
        for depname, depconfig in pairs(table.wrap(self:get("__extra_deps"))) do
            depsconfig[depname] = depconfig
        end
        self._DEPSCONFIG = depsconfig
    end
    return depsconfig[name]
end

-- get target rules
function target:rules()
    return self._RULES
end

-- get target order rules
function target:orderules()
    return self._ORDERULES
end

-- get target rule from the given rule name
function target:rule(name)
    if self._RULES then
        return self._RULES[name]
    end
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

    -- load options if be enabled 
    self._OPTIONS = {}
    for _, name in ipairs(table.wrap(self:get("options"))) do
        local opt = nil
        if config.get(name) then opt = option.load(name) end
        if opt then
            table.insert(self._OPTIONS, opt)
        end
    end

    -- load options from packages if no require info, be compatible with the option package in (*.pkg)
    for _, name in ipairs(table.wrap(self:get("packages"))) do
        if not requireinfo.load(name) then
            local opt = nil
            if config.get(name) then opt = option.load(name) end
            if opt then
                table.insert(self._OPTIONS, opt)
            end
        end
    end

    -- get it 
    return self._OPTIONS
end

-- get the required packages 
function target:packages()
    if not self._PACKAGES_ENABLED then
        local packages = {}
        for _, pkg in ipairs(self._PACKAGES) do
            if pkg:enabled() then
                table.insert(packages, pkg)
            end
        end
        self._PACKAGES_ENABLED = packages
    end
    return self._PACKAGES_ENABLED
end

-- get the config info of the given package 
function target:pkgconfig(pkgname)
    local extra_packages = self:get("__extra_packages")
    if extra_packages then
        return extra_packages[pkgname]
    end
end

-- get the object files directory
function target:objectdir(onlyroot)

    -- the object directory
    local objectdir = self:get("objectdir")
    if not objectdir then
        objectdir = path.join(config.buildir(), ".objs", self:name())
    end

    -- only in the root directory?
    if not onlyroot then

        -- append plat sub-directory
        local plat = config.get("plat")
        if plat then
            objectdir = path.join(objectdir, plat)
        end

        -- append arch sub-directory
        local arch = config.get("arch")
        if arch then
            objectdir = path.join(objectdir, arch)
        end

        -- append mode sub-directory
        local mode = config.get("mode")
        if mode then
            objectdir = path.join(objectdir, mode)
        end
    end

    -- ok?
    return objectdir
end

-- get the dependent files directory
function target:dependir()

    -- init the dependent directory
    local dependir = self:get("dependir")
    if not dependir then
        dependir = path.join(config.buildir(), ".deps", self:name())
    end

    -- ok?
    return dependir
end

-- get the target kind
function target:targetkind()
    return self:get("kind")
end

-- get the target directory
function target:targetdir(onlyroot)

    -- the target directory
    local targetdir = self:get("targetdir") 
    if not targetdir then

        -- get build directory
        targetdir = config.buildir()
        if not onlyroot then

            -- append plat sub-directory
            local plat = config.get("plat")
            if plat then
                targetdir = path.join(targetdir, plat)
            end

            -- append arch sub-directory
            local arch = config.get("arch")
            if arch then
                targetdir = path.join(targetdir, arch)
            end

            -- append mode sub-directory
            local mode = config.get("mode")
            if mode then
                targetdir = path.join(targetdir, mode)
            end
        end
    end

    -- ok?
    return targetdir
end

-- get the target file 
function target:targetfile()

    -- the target directory
    local targetdir = self:targetdir()

    -- get target kind
    local targetkind = self:targetkind()

    -- only compile objects? no target file
    if targetkind == "object" then
        return 
    end

    -- make the target file name and attempt to use the format of linker first
    local filename = self:get("filename") or target.filename(self:basename(), targetkind, self:linker():format(targetkind))
    assert(filename)

    -- make the target file path
    return path.join(targetdir, filename)
end

-- get the symbol file
function target:symbolfile()

    -- the target directory
    local targetdir = self:targetdir() or config.buildir()
    assert(targetdir and type(targetdir) == "string")

    -- the symbol file name
    local filename = target.filename(self:basename(), "symbol")
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
    return self:get("headerdir") or config.buildir()
end

-- get rules of the source file 
function target:filerules(sourcefile)

    -- add rules from file config
    local rules = {}
    local fileconfig = self:fileconfig(sourcefile)
    if fileconfig then
        local filerules = fileconfig.rules or fileconfig.rule 
        if filerules then
            for _, rulename in ipairs(table.wrap(filerules)) do
                local r = self._PROJECT.rule(rulename) or rule.rule(rulename)
                if r then
                    table.insert(rules, r)
                end
            end
        end
    end

    -- get target rule from the given source extension
    local extension2rules = self._EXTENSION2RULES
    if not extension2rules then
        extension2rules = {}
        for _, r in pairs(table.wrap(self:rules())) do
            for _, extension in ipairs(table.wrap(r:get("extensions"))) do
                extension2rules[extension] = extension2rules[extension] or {}
                table.insert(extension2rules[extension], r)
            end
        end
        self._EXTENSION2RULES = extension2rules
    end
    for _, r in ipairs(table.wrap(extension2rules[path.extension(sourcefile)])) do
        table.insert(rules, r)
    end

    -- done
    return rules 
end

-- get the config info of the given source file
function target:fileconfig(sourcefile)

    -- get files config
    local filesconfig = self._FILESCONFIG
    if not filesconfig then
        filesconfig = {}
        for filepath, fileconfig in pairs(table.wrap(self:get("__extra_files"))) do

            -- match source files
            local results = os.match(filepath)
            if #results == 0 then
                local sourceinfo = (self:get("__sourceinfo_files") or {})[filepath] or {}
                utils.warning("cannot match %s(%s).add_files(\"%s\") at %s:%d", self:type(), self:name(), filepath, sourceinfo.file or "", sourceinfo.line or -1)
            end

            -- process source files
            for _, file in ipairs(results) do

                -- convert to the relative path
                if path.is_absolute(file) then
                    file = path.relative(file, os.projectdir())
                end

                -- save it
                filesconfig[file] = fileconfig
            end
        end
        self._FILESCONFIG = filesconfig
    end

    -- get file config
    return filesconfig[sourcefile]
end

-- set the config info to the given source file
function target:fileconfig_set(sourcefile, info)

    -- get files config
    local filesconfig = self._FILESCONFIG or {}

    -- set config info
    filesconfig[sourcefile] = info
    
    -- update files config
    self._FILESCONFIG = filesconfig
end

-- get the source files 
function target:sourcefiles()

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
        {"([%w%*]+)%.obj|",     "%%1|",  "object"}
    ,   {"([%w%*]+)%.obj$",     "%%1",   "object"}
    ,   {"([%w%*]+)%.o|",       "%%1|",  "object"}
    ,   {"([%w%*]+)%.o$",       "%%1",   "object"}
    ,   {"([%w%*]+)%.lib|",     "%%1|",  "static"}
    ,   {"([%w%*]+)%.lib$",     "%%1",   "static"}
    ,   {"lib([%w%*]+)%.a|",    "%%1|",  "static"}
    ,   {"lib([%w%*]+)%.a$",    "%%1",   "static"}
    }

    -- match files
    local i = 1
    local count = 0
    local cache = true
    local sourcefiles = {}
    for _, file in ipairs(table.wrap(files)) do

        -- mark as deleted files?
        local deleted = false
        if file:startswith("__del_") then
            file = file:sub(7)
            deleted = true
        end

        -- normalize *.[o|obj] and [lib]*.[a|lib] filename
        for _, pattern in ipairs(patterns) do
            file, count = file:gsub(pattern[1], target.filename(pattern[2], pattern[3]))
            if count > 0 then
                -- disable cache because the object and library files will be modified if them depend on previous target file
                cache = false
            end
        end

        -- match source files
        local results = os.match(file)
        if #results == 0 then
            local sourceinfo = (self:get("__sourceinfo_files") or {})[file] or {}
            utils.warning("cannot match %s(%s).%s_files(\"%s\") at %s:%d", self:type(), self:name(), utils.ifelse(deleted, "del", "add"), file, sourceinfo.file or "", sourceinfo.line or -1)
        end

        -- process source files
        for _, sourcefile in ipairs(results) do

            -- convert to the relative path
            if path.is_absolute(sourcefile) then
                sourcefile = path.relative(sourcefile, os.projectdir())
            end

            -- add or delete it
            if deleted then
                sourcefiles[sourcefile] = nil
            else
                sourcefiles[sourcefile] = true
            end
        end
    end

    -- make last source files
    local sourcefiles_last = {}
    for sourcefile, _ in pairs(sourcefiles) do
        table.insert(sourcefiles_last, sourcefile)
    end

    -- cache it
    if cache then
        self._SOURCEFILES = sourcefiles_last
    end

    -- ok? modified?
    return sourcefiles_last, not cache
end

-- get object file from source file
function target:objectfile(sourcefile)

    -- translate: [lib]xxx*.[a|lib] => xxx/*.[o|obj] object file
    sourcefile = sourcefile:gsub(target.filename("([%%w%%-_]+)", "static"):gsub("%.", "%%.") .. "$", "%1/*")

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
    local sourcedir = path.directory(sourcefile)
    if path.is_absolute(sourcedir) and os.host() == "windows" then
        sourcedir = sourcedir:gsub(":[\\/]*", '\\') -- replace C:\xxx\ => C\xxx\
    end
    sourcedir = sourcedir:gsub("%.%.", "__")

    -- make object file
    -- full file name(not base) to avoid name-clash of object file
    return path.join(self:objectdir(), sourcedir, target.filename(path.filename(sourcefile), "object"))
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
        if not sourcebatch.rulename then
            table.join2(objectfiles, sourcebatch.objectfiles)
        end
    end

    -- get object files from all dependent targets (object kind)
    if self:orderdeps() then
        local remove_repeat = false
        for _, dep in ipairs(self:orderdeps()) do
            if dep:targetkind() == "object" then
                table.join2(objectfiles, dep:objectfiles())
                remove_repeat = true
            end
        end
        if remove_repeat then
            objectfiles = table.unique(objectfiles)
        end
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

-- get depend file from object file
function target:dependfile(objectfile)

    -- get the dependent original file and directory, @note relative to the root directory
    local originfile = objectfile and objectfile or self:targetfile(true)
    local origindir  = objectfile and self:objectdir(true) or self:targetdir(true)

    -- get the relative directory
    local relativedir = path.directory(path.relative(originfile, origindir))
    if path.is_absolute(relativedir) and os.host() == "windows" then
        relativedir = relativedir:gsub(":[\\/]*", '\\') -- replace C:\xxx\ => C\xxx\
    end

    -- originfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    --
    -- we need replace '..' to '__' in this case
    --
    relativedir = relativedir:gsub("%.%.", "__")

    -- make dependent file
    -- full file name(not base) to avoid name-clash of original file
    return path.join(self:dependir(), relativedir, path.basename(originfile) .. ".d")
end

-- get the dependent include files
function target:dependfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._DEPENDFILES and not modified then
        return self._DEPENDFILES
    end

    -- get dependent files from source batches
    local dependfiles = {}
    for sourcekind, sourcebatch in pairs(self:sourcebatches()) do
        if not sourcebatch.rulename then
            table.join2(dependfiles, sourcebatch.dependfiles)
        end
    end

    -- cache it
    self._DEPENDFILES = dependfiles

    -- ok?
    return dependfiles
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

        -- add file rules
        local builtin_rule = true
        local filerules = self:filerules(sourcefile)
        for _, filerule in ipairs(filerules) do

            -- get source kind
            local sourcekind = "__rule_" .. filerule:name()

            -- make this batch
            local sourcebatch = sourcebatches[sourcekind] or {sourcefiles = {}}
            sourcebatches[sourcekind] = sourcebatch

            -- add source kind to this batch
            sourcebatch.sourcekind = sourcekind

            -- add source rule to this batch
            sourcebatch.rulename = filerule:name()

            -- add source file to this batch
            table.insert(sourcebatch.sourcefiles, sourcefile)

            -- override `on_build_xxx` in filerules? disable the builtin-rule
            if filerule:get("build_file") or filerule:get("build_files") or filerule:get("build") then
                builtin_rule = false
            end
        end

        -- add builtin rule
        if builtin_rule then

            -- get source kind
            sourcekind = language.sourcekind_of(sourcefile)
            if not sourcekind then
                local sourcekind_ext = sourcekinds_ext[path.extension(sourcefile):lower()]
                if sourcekind_ext then
                    sourcekind = sourcekind_ext
                end
            end
            if sourcekind then

                -- make this batch
                local sourcebatch = sourcebatches[sourcekind] or {sourcefiles = {}}
                sourcebatches[sourcekind] = sourcebatch

                -- add source kind to this batch
                sourcebatch.sourcekind = sourcekind

                -- add source file to this batch
                table.insert(sourcebatch.sourcefiles, sourcefile)

            elseif #filerules == 0 then
                os.raise("unknown source file: %s", sourcefile)
            end
        end
    end

    -- insert object files to source batches
    for sourcekind, sourcebatch in pairs(sourcebatches) do

        -- skip source files with the custom rule
        if not sourcebatch.rulename then

            -- this batch support to compile multiple objects at the same time?
            local instance = compiler.load(sourcekind, self)
            if instance and instance:buildmode("object:sources") then

                -- get the first source file
                local sourcefile = sourcebatch.sourcefiles[1]

                -- insert single object file for all source files
                sourcebatch.objectfiles = self:objectfile(path.join(path.directory(sourcefile), "__" .. sourcekind))

                -- insert single dependent file for all source files
                sourcebatch.dependfiles = self:dependfile(sourcebatch.objectfiles)

            else

                -- insert object files for each source files
                sourcebatch.objectfiles = {}
                sourcebatch.dependfiles = {}
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    local objectfile = self:objectfile(sourcefile)
                    table.insert(sourcebatch.objectfiles, objectfile)
                    table.insert(sourcebatch.dependfiles, self:dependfile(objectfile))
                end
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
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- match script for special plat and arch
        local plat = (config.get("plat") or "")
        local pattern = plat .. '|' .. (config.get("arch") or "")
        for _pattern, _script in pairs(script) do
            if not _pattern:startswith("__") and pattern:find('^' .. _pattern .. '$') then
                result = _script
                break
            end
        end

        -- match script for special plat
        if result == nil then
            for _pattern, _script in pairs(script) do
                if not _pattern:startswith("__") and plat:find('^' .. _pattern .. '$') then
                    result = _script
                    break
                end
            end
        end

        -- get generic script
        result = result or script["__generic__"] or generic
    end

    -- only generic script
    result = result or generic

    -- imports some modules first
    if result and result ~= generic then
        local scope = getfenv(result)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end

    -- ok
    return result
end

-- get the config header version
function target:configversion()

    -- get the config version and build version
    local version = nil
    local buildversion = nil
    local configheader = self:get("config_header")
    local configheader_extra = self:get("__extra_config_header")
    if type(configheader_extra) == "table" then
        version      = table.wrap(configheader_extra[configheader]).version
        buildversion = table.wrap(configheader_extra[configheader]).buildversion
    end

    -- ok?
    return version, buildversion
end

-- get the config header prefix
function target:configprefix()

    -- get the config prefix
    local configprefix = nil
    local configheader = self:get("config_header")
    local configheader_extra = self:get("__extra_config_header")
    if type(configheader_extra) == "table" then
        configprefix = table.wrap(configheader_extra[configheader]).prefix
    end
    if not configprefix then
        configprefix = self:get("config_h_prefix") or (self:name():upper() .. "_CONFIG")
    end

    -- ok?
    return configprefix
end

-- get the config header files
function target:configheader(outputdir)

    -- get config header
    local configheader = self:get("config_header") or self:get("config_h")
    if not configheader then
        return 
    end

    -- mark as deprecated
    if self:get("config_h") then
        deprecated.add("set_config_header(\"%s\", {prefix = \"...\"})", "set_config_h(\"%s\")", path.relative(self:get("config_h"), os.projectdir()))
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

-- get the precompiled header file (xxx.[h|hpp|inl])
--
-- @param langkind  c/cxx
--
function target:pcheaderfile(langkind)
    return self:get("p" .. langkind .. "header")
end

-- get the output of precompiled header file (xxx.h.pch)
--
-- @param langkind  c/cxx
--
function target:pcoutputfile(langkind)

    -- init cache
    self._PCOUTPUTFILES = self._PCOUTPUTFILES or {}

    -- get it from the cache first
    local pcoutputfile = self._PCOUTPUTFILES[langkind]
    if pcoutputfile then
        return pcoutputfile
    end
        
    -- get the precompiled header file in the object directory
    local pcheaderfile = self:pcheaderfile(langkind)
    if pcheaderfile then

        -- load tool instance
        local toolinstance = tool.load(language.langkinds()[langkind])

        -- make precompiled output file 
        --
        -- @note gcc has not -include-pch option to set the pch file path
        --
        if toolinstance and toolinstance:name() == "gcc" then
            pcoutputfile = pcheaderfile .. ".gch"
        else
            local headerdir = path.directory(pcheaderfile):gsub("%.%.", "__")
            pcoutputfile = string.format("%s/%s/%s/%s", self:objectdir(), self:name(), headerdir, path.filename(pcheaderfile) .. ".pch")
        end

        -- save to cache
        self._PCOUTPUTFILES[langkind] = pcoutputfile
        return pcoutputfile
    end
end

-- return module
return target
