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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        target.lua
--

-- define module
local target    = target or {}
local _instance = _instance or {}

-- load modules
local bit            = require("bit")
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local baseoption     = require("base/option")
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

-- new a target instance
function _instance.new(name, info, project)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._PROJECT = project
    instance._CACHEID = 1
    return instance
end

-- load rule, move cache to target
function _instance:_load_rule(ruleinst, suffix)

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
function _instance:_load_rules(suffix)
    for _, r in pairs(self:orderules()) do
        local ok, errors = self:_load_rule(r, suffix)
        if not ok then
            return false, errors
        end
    end
    return true
end

-- load all
function _instance:_load_all()

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
    return true
end

-- do load target and rules
function _instance:_load()

    -- enter the environments of the target packages
    local oldenvs = {}
    for name, values in pairs(self:pkgenvs()) do
        oldenvs[name] = os.getenv(name)
        os.addenv(name, unpack(values))
    end

    -- load all
    local ok, errors = self:_load_all()
    if not ok then
        return false, errors
    end

    -- leave the environments of the target packages
    for name, values in pairs(oldenvs) do
        os.setenv(name, values)
    end
    return true
end

-- get the copied files
function _instance:_copiedfiles(filetype, outputdir, pathfilter)

    -- no copied files?
    local copiedfiles = self:get(filetype)
    if not copiedfiles then return end

    -- get the extra information
    local extrainfo = table.wrap(self:get("__extra_" .. filetype))

    -- get the source pathes and destinate pathes
    local srcfiles = {}
    local dstfiles = {}
    local fileinfos = {}
    for _, copiedfile in ipairs(table.wrap(copiedfiles)) do

        -- get the root directory
        local rootdir, count = copiedfile:gsub("|.*$", ""):gsub("%(.*%)$", "")
        if count == 0 then
            rootdir = nil
        end

        -- remove '(' and ')'
        local srcpathes = copiedfile:gsub("[%(%)]", "")
        if srcpathes then 

            -- get the source pathes
            srcpathes = os.match(srcpathes)
            if srcpathes and #srcpathes > 0 then

                -- add the source copied files
                table.join2(srcfiles, srcpathes)

                -- the copied directory exists?
                if outputdir then

                    -- get the file info
                    local fileinfo = extrainfo[copiedfile] or {}

                    -- get the prefix directory
                    local prefixdir = fileinfo.prefixdir

                    -- add the destinate copied files
                    for _, srcpath in ipairs(srcpathes) do

                        -- get the destinate directory
                        local dstdir = outputdir
                        if prefixdir then
                            dstdir = path.join(dstdir, prefixdir)
                        end

                        -- the destinate file
                        local dstfile = nil
                        if rootdir then
                            dstfile = path.absolute(path.relative(srcpath, rootdir), dstdir)
                        else
                            dstfile = path.join(dstdir, path.filename(srcpath))
                        end
                        assert(dstfile)

                        -- modify filename
                        if fileinfo.filename then
                            dstfile = path.join(path.directory(dstfile), fileinfo.filename)
                        end

                        -- filter the destinate file path
                        if pathfilter then
                            dstfile = pathfilter(dstfile, fileinfo)
                        end

                        -- add it
                        table.insert(dstfiles, dstfile)
                        table.insert(fileinfos, fileinfo)
                    end
                end
            end
        end
    end
    return srcfiles, dstfiles, fileinfos
end

-- get the visibility, private: 1, interface: 2, public: 3 = 1 | 2
function _instance:_visibility(opt)
    local visibility = 1
    if opt then
        if opt.interface then
            visibility = 2
        elseif opt.public then
            visibility = 3
        end
    end
    return visibility
end

-- invalidate the previous cache key
function _instance:_invalidate()
    self._CACHEID = self._CACHEID + 1
end

-- get the target info
--
-- e.g. 
--
-- default: get private
--  - target:get("cflags")
--  - target:get("cflags", {private = true})
--
-- get private and interface
--  - target:get("cflags", {public = true})
--
-- get interface
--  - target:get("cflags", {interface = true})
--
function _instance:get(name, opt)

    -- get values
    local values = self._INFO:get(name)

    -- get thr required visibility
    local vs_private   = 1
    local vs_interface = 2
    local vs_public    = 3 -- all
    local vs_required  = self:_visibility(opt)

    -- get all values? (private and interface)
    if vs_required == vs_public then
        return values
    end

    -- get the extra configuration
    local extraconf = self._INFO:extraconf(name)
    if extraconf then
        -- filter values for public, private or interface if be not dictionary
        if not table.is_dictionary(values) then
            local results = {}
            for _, value in ipairs(table.wrap(values)) do
                local vs_conf = self:_visibility(extraconf[value])
                if bit.band(vs_required, vs_conf) ~= 0 then
                    table.insert(results, value)
                end
            end
            if #results > 0 then
                return table.unwrap(results)
            end
        else
            return values
        end
    else
        -- only get thr private values
        if bit.band(vs_required, vs_private) ~= 0 then
            return values
        end
    end
end

-- set the value to the target info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
    self:_invalidate()
end

-- add the value to the target info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
    self:_invalidate()
end

-- remove the value to the target info
function _instance:del(name, ...)
    self._INFO:apival_del(name, ...)
    self:_invalidate()
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- get user private data
function _instance:data(name)
    return self._DATA and self._DATA[name] or nil
end

-- set user private data
function _instance:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function _instance:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
end

-- get values
function _instance:values(name, sourcefile)

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
    if #values > 0 then
        values = table.unwrap(values) 
    else
        values = nil
    end
    return values
end

-- set values
function _instance:values_set(name, ...)
    self:set("values." .. name, ...)
end

-- add values
function _instance:values_add(name, ...)
    self:add("values." .. name, ...)
end

-- get the target info
function _instance:info()
    return self._INFO:info()
end

-- get the type: option
function _instance:type()
    return "target"
end

-- get the target name
function _instance:name()
    return self._NAME
end

-- get the cache key 
function _instance:cachekey()
    return string.format("%s_%d", tostring(self), self._CACHEID)
end

-- get the target version
function _instance:version()

    -- get version and build version
    local version = self:get("version")
    local version_build = nil
    if version then
        local version_extra = self:get("__extra_version")
        if version_extra then
            version_build = self._VERSION_BUILD
            if not version_build then
                version_build = table.wrap(version_extra[version]).build
                if type(version_build) == "string" then
                    version_build = os.date(version_build, os.time())
                    self._VERSION_BUILD = version_build
                end
            end
        end
    end

    -- ok?
    return version, version_build
end

-- get the base name of target file
function _instance:basename()
    local filename = self:get("filename")
    if filename then
        return path.basename(filename)
    end
    return self:get("basename") or self:name()
end

-- get the target linker
function _instance:linker()

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
function _instance:linkcmd(objectfiles)
    return self:linker():linkcmd(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make linking arguments for this target 
function _instance:linkargv(objectfiles)
    return self:linker():linkargv(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make link flags for the given target
function _instance:linkflags()
    return self:linker():linkflags({target = self})
end

-- get the given dependent target
function _instance:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get target deps
function _instance:deps()
    return self._DEPS
end

-- get target ordered deps
function _instance:orderdeps()
    return self._ORDERDEPS
end

-- get target rules
function _instance:rules()
    return self._RULES
end

-- get target ordered rules
function _instance:orderules()
    return self._ORDERULES
end

-- get target rule from the given rule name
function _instance:rule(name)
    if self._RULES then
        return self._RULES[name]
    end
end

-- is phony target?
function _instance:isphony()
    
    -- get target kind
    local targetkind = self:targetkind()

    -- is phony?
    return not targetkind or targetkind == "phony"
end

-- get the enabled option
function _instance:opt(name)
    return self:opts()[name]
end

-- get the enabled options
function _instance:opts()

    -- attempt to get it from cache first
    if self._OPTS_ENABLED then
        return self._OPTS_ENABLED
    end

    -- load options if be enabled 
    self._OPTS_ENABLED = {}
    for _, opt in ipairs(self:orderopts()) do
        self._OPTS_ENABLED[opt:name()] = opt
    end

    -- get it 
    return self._OPTS_ENABLED
end

-- get the enabled ordered options 
function _instance:orderopts()

    -- attempt to get it from cache first
    if self._ORDEROPTS_ENABLED then
        return self._ORDEROPTS_ENABLED
    end

    -- load options if be enabled 
    self._ORDEROPTS_ENABLED = {}
    for _, name in ipairs(table.wrap(self:get("options"))) do
        local opt = nil
        if config.get(name) then opt = option.load(name) end
        if opt then
            table.insert(self._ORDEROPTS_ENABLED, opt)
        end
    end

    -- load options from packages if no require info, be compatible with the option package in (*.pkg)
    for _, name in ipairs(table.wrap(self:get("packages"))) do
        if not requireinfo.load(name) then
            local opt = nil
            if config.get(name) then opt = option.load(name) end
            if opt then
                table.insert(self._ORDEROPTS_ENABLED, opt)
            end
        end
    end

    -- get it 
    return self._ORDEROPTS_ENABLED
end

-- get the enabled package
function _instance:pkg(name)
    return self:pkgs()[name]
end

-- get the enabled packages
function _instance:pkgs()

    -- attempt to get it from cache first
    if self._PKGS_ENABLED then
        return self._PKGS_ENABLED
    end

    -- load packages if be enabled 
    self._PKGS_ENABLED = {}
    for _, pkg in ipairs(self:orderpkgs()) do
        self._PKGS_ENABLED[pkg:name()] = pkg
    end

    -- get it 
    return self._PKGS_ENABLED
end

-- get the required packages 
function _instance:orderpkgs()
    if not self._ORDERPKGS_ENABLED then
        local packages = {}
        for _, pkg in ipairs(self._PACKAGES) do
            if pkg:enabled() then
                table.insert(packages, pkg)
            end
        end
        self._ORDERPKGS_ENABLED = packages
    end
    return self._ORDERPKGS_ENABLED
end

-- get the environments of packages
function _instance:pkgenvs()
    local pkgenvs = self._PKGENVS 
    if not pkgenvs then
        pkgenvs = {}
        self._PKGENVS = pkgenvs
        for _, pkgname in ipairs(table.wrap(self:get("packages"))) do
            local pkg = self:pkg(pkgname)
            if pkg then
                local envs = pkg:get("envs")
                if envs then
                    for name, values in pairs(envs) do
                        pkgenvs[name] = pkgenvs[name] or {}
                        table.join2(pkgenvs[name], values)
                    end
                end
            end
        end
    end
    return pkgenvs
end

-- get the config info of the given package 
function _instance:pkgconfig(pkgname)
    local extra_packages = self:get("__extra_packages")
    if extra_packages then
        return extra_packages[pkgname]
    end
end

-- get the object files directory
function _instance:objectdir(opt)

    -- the object directory
    local objectdir = self:get("objectdir")
    if not objectdir then
        objectdir = path.join(config.buildir(), ".objs")
    end
    objectdir = path.join(objectdir, self:name())

    -- get root directory of target
    if opt and opt.root then
        return objectdir
    end

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
    return objectdir
end

-- get the dependent files directory
function _instance:dependir(opt)

    -- init the dependent directory
    local dependir = self:get("dependir")
    if not dependir then
        dependir = path.join(config.buildir(), ".deps")
    end
    dependir = path.join(dependir, self:name())

    -- get root directory of target
    if opt and opt.root then
        return dependir
    end

    -- append plat sub-directory
    local plat = config.get("plat")
    if plat then
        dependir = path.join(dependir, plat)
    end

    -- append arch sub-directory
    local arch = config.get("arch")
    if arch then
        dependir = path.join(dependir, arch)
    end

    -- append mode sub-directory
    local mode = config.get("mode")
    if mode then
        dependir = path.join(dependir, mode)
    end
    return dependir
end

-- get the autogen files directory
function _instance:autogendir(opt)

    -- the autogen directory
    local autogendir = path.join(config.buildir(), ".gens", self:name())

    -- get root directory of target
    if opt and opt.root then
        return autogendir
    end

    -- append plat sub-directory
    local plat = config.get("plat")
    if plat then
        autogendir = path.join(autogendir, plat)
    end

    -- append arch sub-directory
    local arch = config.get("arch")
    if arch then
        autogendir = path.join(autogendir, arch)
    end

    -- append mode sub-directory
    local mode = config.get("mode")
    if mode then
        autogendir = path.join(autogendir, mode)
    end
    return autogendir
end

-- get the target kind
function _instance:targetkind()
    return self:get("kind") or "phony"
end

-- get the target directory
function _instance:targetdir()

    -- the target directory
    local targetdir = self:get("targetdir") 
    if not targetdir then

        -- get build directory
        targetdir = config.buildir()

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

    -- ok?
    return targetdir
end

-- get the target file 
function _instance:targetfile()

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
function _instance:symbolfile()

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
function _instance:scriptdir()
    return self:get("__scriptdir")
end

-- TODO get header directory (deprecated)
function _instance:headerdir()
    return self:get("headerdir") or config.buildir()
end

-- get configuration output directory
function _instance:configdir()
    return self:get("configdir") or config.buildir()
end

-- get run directory
function _instance:rundir()
    return baseoption.get("workdir") or self:get("rundir") or path.directory(self:targetfile())
end

-- get install directory
function _instance:installdir()

    -- get it from the cache
    local installdir = self._INSTALLDIR
    if not installdir then

        -- get it from target
        installdir = self:get("installdir")
        if not installdir then

            -- DESTDIR: be compatible with https://www.gnu.org/prep/standards/html_node/DESTDIR.html
            installdir = baseoption.get("installdir") or os.getenv("INSTALLDIR") or os.getenv("PREFIX") or os.getenv("DESTDIR") or platform.get("installdir")
            if installdir then
                installdir = installdir:trim()
            end
        end
        self._INSTALLDIR = installdir or false
    end

    -- ok
    return installdir or nil
end

-- get rules of the source file 
function _instance:filerules(sourcefile)

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
                extension = extension:lower()
                extension2rules[extension] = extension2rules[extension] or {}
                table.insert(extension2rules[extension], r)
            end
        end
        self._EXTENSION2RULES = extension2rules
    end
    for _, r in ipairs(table.wrap(extension2rules[path.extension(sourcefile):lower()])) do
        table.insert(rules, r)
    end

    -- done
    return rules 
end

-- get the config info of the given source file
function _instance:fileconfig(sourcefile)

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
function _instance:fileconfig_set(sourcefile, info)

    -- get files config
    local filesconfig = self._FILESCONFIG or {}

    -- set config info
    filesconfig[sourcefile] = info
    
    -- update files config
    self._FILESCONFIG = filesconfig
end

-- get the source files 
function _instance:sourcefiles()

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
function _instance:objectfile(sourcefile)

    -- get relative directory in the autogen directory
    local relativedir = nil
    local origindir  = path.directory(path.absolute(sourcefile))
    local autogendir = path.absolute(self:autogendir())
    if origindir:startswith(autogendir) then
        relativedir = path.join("gens", path.relative(origindir, autogendir))
    end

    -- get relative directory in the source directory
    if not relativedir then
        relativedir = path.directory(sourcefile)
    end

    -- translate path
    --
    -- e.g. 
    --
    -- src/xxx.c
    --      project/xmake.lua
    --          build/.objs
    --
    -- objectfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    --
    -- we need replace '..' to '__' in this case
    --
    if path.is_absolute(relativedir) and os.host() == "windows" then
        relativedir = relativedir:gsub(":[\\/]*", '\\') -- replace C:\xxx\ => C\xxx\
    end
    relativedir = relativedir:gsub("%.%.", "__")

    -- make object file
    -- full file name(not base) to avoid name-clash of object file
    return path.join(self:objectdir(), relativedir, target.filename(path.filename(sourcefile), "object"))
end

-- get the object files
function _instance:objectfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._OBJECTFILES and not modified then
        return self._OBJECTFILES
    end

    -- get object files from source batches
    local objectfiles = {}
    for _, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(objectfiles, sourcebatch.objectfiles)
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

-- TODO get the header files, get("headers") (deprecated)
function _instance:headers(outputdir)
    return self:headerfiles(outputdir, true)
end

-- get the header files
--
-- default: get("headers") + get("headerfiles")
-- only_deprecated: get("headers")
--
function _instance:headerfiles(outputdir, only_deprecated)

    -- get header files?
    local headers = self:get("headers") -- TODO deprecated
    if not only_deprecated then
       headers = table.join(headers or {}, self:get("headerfiles")) 
    end
    if not headers then return end

    -- get the installed header directory
    local headerdir = outputdir 
    if not headerdir then
        if only_deprecated then
            headerdir = self:headerdir()
        elseif self:installdir() then
            headerdir = path.join(self:installdir(), "include")
        end
    end

    -- get the extra information
    local extrainfo = table.wrap(self:get("__extra_headerfiles"))

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

                -- get the destinate directories if the install directory exists
                if headerdir then

                    -- get the prefix directory
                    local prefixdir = (extrainfo[header] or {}).prefixdir

                    -- add the destinate headers
                    for _, srcpath in ipairs(srcpathes) do

                        -- get the destinate directory
                        local dstdir = headerdir
                        if prefixdir then
                            dstdir = path.join(dstdir, prefixdir)
                        end

                        -- the destinate header
                        local dstheader = nil
                        if rootdir then
                            dstheader = path.absolute(path.relative(srcpath, rootdir), dstdir)
                        else
                            dstheader = path.join(dstdir, path.filename(srcpath))
                        end
                        assert(dstheader)

                        -- add it
                        table.insert(dstheaders, dstheader)
                    end
                end
            end
        end
    end

    -- ok?
    return srcheaders, dstheaders
end

-- get the configuration files
function _instance:configfiles(outputdir)
    return self:_copiedfiles("configfiles", outputdir or self:configdir(), function (dstpath, fileinfo)
            if dstpath:endswith(".in") then
                dstpath = dstpath:sub(1, -4)
            end
            return dstpath
        end)
end

-- get the install files
function _instance:installfiles(outputdir)
    return self:_copiedfiles("installfiles", outputdir or self:installdir())
end

-- get depend file from object file
function _instance:dependfile(objectfile)

    -- get the dependent original file and directory, @note relative to the root directory
    local originfile = path.absolute(objectfile and objectfile or self:targetfile())
    local origindir  = path.directory(originfile)

    -- get relative directory in the object directory
    local relativedir = nil
    local objectdir = path.absolute(self:objectdir())
    if origindir:startswith(objectdir) then
        relativedir = path.relative(origindir, objectdir)
    end

    -- get relative directory in the target directory
    if not relativedir then
        local targetdir = path.absolute(self:targetdir())
        if origindir:startswith(targetdir) then
            relativedir = path.relative(origindir, targetdir)
        end
    end

    -- get relative directory in the autogen directory
    if not relativedir then
        local autogendir = path.absolute(self:autogendir())
        if origindir:startswith(autogendir) then
            relativedir = path.join("gens", path.relative(origindir, autogendir))
        end
    end

    -- get relative directory in the build directory
    if not relativedir then
        local buildir = path.absolute(config.buildir())
        if origindir:startswith(buildir) then
            relativedir = path.join("build", path.relative(origindir, buildir))
        end
    end

    -- get relative directory in the project directory
    if not relativedir then
        local projectdir = os.projectdir()
        if origindir:startswith(projectdir) then
            relativedir = path.relative(origindir, projectdir)
        end
    end

    -- get the relative directory from the origin file
    if not relativedir then
        relativedir = origindir
    end
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
function _instance:dependfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._DEPENDFILES and not modified then
        return self._DEPENDFILES
    end

    -- get dependent files from source batches
    local dependfiles = {}
    for _, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(dependfiles, sourcebatch.dependfiles)
    end

    -- cache it
    self._DEPENDFILES = dependfiles

    -- ok?
    return dependfiles
end

-- get the kinds of sourcefiles
--
-- e.g. cc cxx mm mxx as ...
--
function _instance:sourcekinds()

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
function _instance:sourcecount()
    return #self:sourcefiles()
end

-- get source batches
function _instance:sourcebatches()

    -- get source files
    local sourcefiles, modified = self:sourcefiles()

    -- cached? return it directly
    if self._SOURCEBATCHES and not modified then
        return self._SOURCEBATCHES, false
    end

    -- make source batches for each source kinds
    local sourcebatches = {}
    for _, sourcefile in ipairs(sourcefiles) do

        -- get file rules
        local filerules = self:filerules(sourcefile)
        if #filerules == 0 then
            os.raise("unknown source file: %s", sourcefile)
        end

        -- add source batch for the file rules
        for _, filerule in ipairs(filerules) do

            -- get rule name
            local rulename = filerule:name()

            -- make this batch
            local sourcebatch = sourcebatches[rulename] or {sourcefiles = {}}
            sourcebatches[rulename] = sourcebatch

            -- save the rule name
            sourcebatch.rulename = rulename

            -- add source file to this batch
            table.insert(sourcebatch.sourcefiles, sourcefile)

            -- attempt to get source kind from the builtin languages
            local sourcekind = language.sourcekind_of(sourcefile)
            if sourcekind then

                -- save source kind
                sourcebatch.sourcekind = sourcekind

                -- insert object files to source batches
                sourcebatch.objectfiles = sourcebatch.objectfiles or {}
                sourcebatch.dependfiles = sourcebatch.dependfiles or {}
                local objectfile = self:objectfile(sourcefile)
                table.insert(sourcebatch.objectfiles, objectfile)
                table.insert(sourcebatch.dependfiles, self:dependfile(objectfile))
            end
        end
    end

    -- cache it
    self._SOURCEBATCHES = sourcebatches

    -- ok?
    return sourcebatches, modified
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- get plat and arch
        local plat = config.get("plat") or ""
        local arch = config.get("arch") or ""

        -- match pattern
        --
        -- `@linux`
        -- `@linux|x86_64`
        -- `@macosx,linux`
        -- `android@macosx,linux`
        -- `android|armv7-a@macosx,linux`
        -- `android|armv7-a@macosx,linux|x86_64`
        -- `android|armv7-a@linux|x86_64`
        --
        for _pattern, _script in pairs(script) do
            local hosts = {}
            local hosts_spec = false
            _pattern = _pattern:gsub("@(.+)", function (v) 
                for _, host in ipairs(v:split(',')) do
                    hosts[host] = true
                    hosts_spec = true
                end
                return "" 
            end)
            if not _pattern:startswith("__") and (not hosts_spec or hosts[os.host() .. '|' .. os.arch()] or hosts[os.host()])  
            and (_pattern:trim() == "" or (plat .. '|' .. arch):find('^' .. _pattern .. '$') or plat:find('^' .. _pattern .. '$')) then
                result = _script
                break
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

-- TODO get the config header version (deprecated)
function _instance:configversion()

    -- get the config version and build version
    local version = nil
    local buildversion = nil
    local configheader = self:get("config_header")
    local configheader_extra = self:get("__extra_config_header")
    if type(configheader_extra) == "table" then
        version      = table.wrap(configheader_extra[configheader]).version
        buildversion = self._CONFIGHEADER_BUILDVERSION
        if not buildversion then
            buildversion = table.wrap(configheader_extra[configheader]).buildversion
            if buildversion then
                buildversion = os.date(buildversion, os.time())
            end
            self._CONFIGHEADER_BUILDVERSION = buildversion
        end
    end

    -- ok?
    return version, buildversion
end

-- get the config header prefix
function _instance:configprefix()

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

-- get the config header files (deprecated)
function _instance:configheader(outputdir)

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
function _instance:pcheaderfile(langkind)
    return self:get("p" .. langkind .. "header")
end

-- get the output of precompiled header file (xxx.h.pch)
--
-- @param langkind  c/cxx
--
function _instance:pcoutputfile(langkind)

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
        pcoutputfile = self:objectfile(pcheaderfile)
        pcoutputfile = path.join(path.directory(pcoutputfile), path.basename(pcoutputfile) .. (toolinstance and toolinstance:name() == "gcc" and ".gch" or ".pch"))

        -- save to cache
        self._PCOUTPUTFILES[langkind] = pcoutputfile
        return pcoutputfile
    end
end

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
        ,   "target.set_version"
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
        ,   "target.set_configvar"
        ,   "target.set_runenv"
        ,   "target.set_toolchain"
            -- target.add_xxx
        ,   "target.add_values"
        ,   "target.add_runenvs"
        }
    ,   pathes =
        {
            -- target.set_xxx
            "target.set_targetdir"
        ,   "target.set_objectdir"
        ,   "target.set_dependir"
        ,   "target.set_configdir"
        ,   "target.set_installdir"
        ,   "target.set_rundir"
            -- target.add_xxx
        ,   "target.add_files"
        ,   "target.add_cleanfiles"
        ,   "target.add_configfiles"
        ,   "target.add_installfiles"
            -- target.del_xxx
        ,   "target.del_files"
        }
    ,   dictionary =
        {
            -- target.set_xxx
            "target.set_tools" -- TODO: deprecated
        ,   "target.add_tools" -- TODO: deprecated
        }
    ,   script =
        {
            -- target.on_xxx
            "target.on_run"
        ,   "target.on_load"
        ,   "target.on_link"
        ,   "target.on_build"
        ,   "target.on_build_file"
        ,   "target.on_build_files"
        ,   "target.on_clean"
        ,   "target.on_package"
        ,   "target.on_install"
        ,   "target.on_uninstall"
            -- target.before_xxx
        ,   "target.before_run"
        ,   "target.before_link"
        ,   "target.before_build"
        ,   "target.before_build_file"
        ,   "target.before_build_files"
        ,   "target.before_clean"
        ,   "target.before_package"
        ,   "target.before_install"
        ,   "target.before_uninstall"
            -- target.after_xxx
        ,   "target.after_run"
        ,   "target.after_link"
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
    if count == 0 and config.is_plat("mingw") then
        -- for the mingw platform, it is compatible with the libxxx.a and xxx.lib
        local formats = {static = "lib$(name).a", shared = "lib$(name).so"}
        linkname, count = filename:gsub(target.filename("__pattern__", "static", formats["static"]):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
        if count == 0 then
            linkname, count = filename:gsub(target.filename("__pattern__", "shared", formats["shared"]):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
        end
    end
    return count > 0 and linkname or nil
end

-- new a target instance
function target.new(...)
    return _instance.new(...)
end

-- return module
return target
