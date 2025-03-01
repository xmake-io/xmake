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
-- @author      ruki, Arthapz
-- @file        compiler_support.lua
--

-- imports
import("core.base.json")
import("core.base.hashset")
import("core.cache.memcache", {alias = "_memcache"})
import("core.cache.localcache", {alias = "_localcache"})
import("lib.detect.find_file")
import("core.project.project")
import("core.project.config")

function _compiler_support(target)
    local cachekey = tostring(target)
    local compiler_support = memcache():get2("compiler_support", cachekey)
    if compiler_support == nil then
        if target:has_tool("cxx", "clang", "clangxx", "clang_cl") then
            compiler_support = import("clang.compiler_support", {anonymous = true})
        elseif target:has_tool("cxx", "gcc", "gxx") then
            compiler_support = import("gcc.compiler_support", {anonymous = true})
        elseif target:has_tool("cxx", "cl") then
            compiler_support = import("msvc.compiler_support", {anonymous = true})
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end
        memcache():set2("compiler_support", cachekey, compiler_support)
    end
    return compiler_support
end

-- load module support for the current target
function load(target)

    -- At least std c++20 is required, and we should call `set_languages("c++20")` to set it
    local languages = target:get("languages")
    local cxxlang = false
    for _, lang in ipairs(languages) do
        if lang:find("cxx", 1, true) or lang:find("c++", 1, true) or lang:find("gnuxx", 1, true) or lang:find("gnu++", 1, true) then
            cxxlang = true
            break
        end
    end
    if not cxxlang then
        target:add("languages", "c++20")
    end

    -- load module support for the specific compiler
    _compiler_support(target).load(target)
end

-- strip flags not relevent for module reuse
function strip_flags(target, flags)
    return _compiler_support(target).strip_flags(target, flags)
end

-- patch sourcebatch
function patch_sourcebatch(target, sourcebatch)
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = {}
    sourcebatch.dependfiles = {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        table.insert(sourcebatch.objectfiles, objectfile)

        local dependfile = target:dependfile(sourcefile or objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end
end

-- get bmi extension
function get_bmi_extension(target)
    return _compiler_support(target).get_bmi_extension()
end

-- get bmi path
-- @see https://github.com/xmake-io/xmake/issues/4063
function get_bmi_path(bmifile)
    bmifile = bmifile:gsub(":", "_PARTITION_")
    return path.normalize(bmifile)
end

-- has module extension? e.g. *.mpp, ...
function has_module_extension(sourcefile)
    local modulexts = _g.modulexts
    if modulexts == nil then
        modulexts = hashset.of(".mpp", ".mxx", ".cppm", ".ixx")
        _g.modulexts = modulexts
    end
    local extension = path.extension(sourcefile)
    return modulexts:has(extension:lower())
end

-- this target contains module files?
function contains_modules(target)
    -- we can not use `"c++.build.builder"`, because it contains sourcekind/cxx.
    local target_with_modules = target:sourcebatches()["c++.build.modules"] and true or false
    if not target_with_modules then
        target_with_modules = target:policy("build.c++.modules")
    end
    if not target_with_modules then
        for _, dep in ipairs(target:orderdeps()) do
            local sourcebatches = dep:sourcebatches()
            if sourcebatches["c++.build.modules"] then
                target_with_modules = true
                break
            end
        end
    end
    return target_with_modules
end

-- load module infos
function load_moduleinfos(target, sourcebatch)
    local moduleinfos
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        if os.isfile(dependfile) then
            local data = io.load(dependfile)
            if data then
                moduleinfos = moduleinfos or {}
                local moduleinfo = json.decode(data.moduleinfo)
                moduleinfo.sourcefile = sourcefile
                if moduleinfo then
                    table.insert(moduleinfos, moduleinfo)
                end
            end
        end
    end
    return moduleinfos
end

function find_quote_header_file(target, sourcefile, file)
    local p = path.join(path.directory(path.absolute(sourcefile, project.directory())), file)
    assert(os.isfile(p))
    return p
end

function find_angle_header_file(target, file)
    local headerpaths = _compiler_support(target).toolchain_includedirs(target)
    for _, dep in ipairs(target:orderdeps()) do
        local includedirs = table.join(dep:get("sysincludedirs") or {}, dep:get("includedirs") or {})
        table.join2(headerpaths, includedirs)
    end
    for _, pkg in ipairs(target:orderpkgs()) do
        local includedirs = table.join(pkg:get("sysincludedirs") or {}, pkg:get("includedirs") or {})
        table.join2(headerpaths, includedirs)
    end
    table.join2(headerpaths, target:get("includedirs"))
    local p = find_file(file, headerpaths)
    assert(p, "find <%s> not found!", file)
    return p
end

-- get stdmodules
function get_stdmodules(target)
  return _compiler_support(target).get_stdmodules(target)
end

-- get memcache
function memcache()
    return _memcache.cache("cxxmodules")
end

-- get localcache
function localcache()
    return _localcache.cache("cxxmodules")
end


-- get stl headerunits cache directory
function stlheaderunits_cachedir(target, opt)
    opt = opt or {}
    local stlcachedir = path.join(target:autogendir(), "rules", "bmi", "cache", "stl-headerunits")
    if opt.mkdir and not os.isdir(stlcachedir) then
        os.mkdir(stlcachedir)
        os.mkdir(path.join(stlcachedir, "experimental"))
    end
    return stlcachedir
end
-- get stl modules cache directory
function stlmodules_cachedir(target, opt)
    opt = opt or {}
    local stlcachedir = path.join(target:autogendir(), "rules", "bmi", "cache", "stl-modules")
    if opt.mkdir and not os.isdir(stlcachedir) then
        os.mkdir(stlcachedir)
    end
    return stlcachedir
end

-- get headerunits cache directory
function headerunits_cachedir(target, opt)
    opt = opt or {}
    local cachedir = path.join(target:autogendir(), "rules", "bmi", "cache", "headerunits")
    if opt.mkdir and not os.isdir(cachedir) then
        os.mkdir(cachedir)
    end
    return cachedir
end

-- get modules cache directory
function modules_cachedir(target, opt)
    opt = opt or {}
    local cachedir = path.join(target:autogendir(), "rules", "bmi", "cache", "modules")
    if opt.mkdir and not os.isdir(cachedir) then
        os.mkdir(cachedir)
    end
    return cachedir
end

function get_modulehash(target, modulepath)
    local key = path.directory(modulepath) .. target:name()
    return hash.uuid(key):split("-", {plain = true})[1]:lower()
end

function get_metafile(target, modulefile)
    local outputdir = get_outputdir(target, modulefile)
    return path.join(outputdir, path.filename(modulefile) .. ".meta-info")
end

function get_outputdir(target, module)
    local cachedir = module and modules_cachedir(target) or headerunits_cachedir(target)
    local modulehash = get_modulehash(target, module.path or module)
    local outputdir = path.join(cachedir, modulehash)
    if not os.exists(outputdir) then
        os.mkdir(outputdir)
    end
    return outputdir
end

-- get name provide info and cpp sourcefile of a module
function get_provided_module(module)

    local name, provide, cppfile
    if module.provides then
        -- assume there that provides is only one, until we encounter the cases
        -- "Some compiler may choose to implement the :private module partition as a separate module for lookup purposes, and if so, it should be indicated as a separate provides entry."
        local length = 0
        for k, v in pairs(module.provides) do
            length = length + 1
            name = k
            provide = v
            cppfile = provide.sourcefile
            if length > 1 then
                raise("multiple provides are not supported now!")
            end
            break
        end
    end

    return name, provide, cppfile
end

function add_installfiles_for_modules(target)
    local sourcebatch = target:sourcebatches()["c++.build.modules.install"]
    if sourcebatch and sourcebatch.sourcefiles then
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local fileconfig = target:fileconfig(sourcefile)
            local install = fileconfig and fileconfig.public or false
            if install then
                local modulehash = get_modulehash(target, sourcefile)
                local prefixdir = path.join("modules", modulehash)
                target:add("installfiles", sourcefile, {prefixdir = prefixdir})
                local metafile = get_metafile(target, sourcefile)
                if os.exists(metafile) then
                    target:add("installfiles", metafile, {prefixdir = prefixdir})
                end
            end
        end
    end
end

