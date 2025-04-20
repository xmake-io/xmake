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
-- @file        support.lua
--

-- imports
import("core.base.bytes")
import("core.base.option")
import("core.base.json")
import("core.base.hashset")
import("core.cache.memcache", {alias = "_memcache"})
import("core.cache.localcache", {alias = "_localcache"})
import("lib.detect.find_file")
import("core.project.project")
import("core.project.config")

function _support(target)
    return import_implementation_of(target, "support")
end

function import_implementation_of(target, name)

    local cachekey = tostring(target)
    local implementation = memcache():get2(name, cachekey)
    if implementation == nil then
        if target:has_tool("cxx", "clang", "clangxx", "clang_cl") then
            implementation = import("clang." .. name, {anonymous = true})
        elseif target:has_tool("cxx", "gcc", "gxx") then
            implementation = import("gcc." .. name, {anonymous = true})
        elseif target:has_tool("cxx", "cl") then
            implementation = import("msvc." .. name, {anonymous = true})
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not implementation c++ module!", toolname)
        end
        memcache():set2(name, cachekey, implementation)
    end
    return implementation
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
    _support(target).load(target)
end

function has_two_phase_compilation_support(target)
    return _support(target).has_two_phase_compilation_support(target)
end

-- strip module mapper flag
function strip_mapper_flags(target, flags)
    if _support(target).strip_mapper_flags then
        return _support(target).strip_mapper_flag(flags)
    else
        return flags
    end
end

-- strip flags not relevent for module reuse
function strip_flags(target, flags, opt)

    local strippeable_flags, splitted_strippeable_flags =  _support(target).strippeable_flags()

    if opt and opt.strip_defines then
        table.join2(splitted_strippeable_flags, {"D", "U"})
    end

    local splitted_strippeable_flags_set = hashset.new()
    for _, flag in ipairs(splitted_strippeable_flags) do
        table.insert(strippeable_flags, flag)
        splitted_strippeable_flags_set:insert("/" .. flag)
        splitted_strippeable_flags_set:insert("-" .. flag)
    end

    local output = {}
    local strip_next_flag = false
    for _, flag in ipairs(flags) do
        local strip = false

        if strip_next_flag then
            strip = true
            strip_next_flag = false
        else
            for _, _flag in ipairs(strippeable_flags) do
                if (flag == "/" .. _flag) or (flag == "-" .. _flag) then
                    strip = true
                    strip_next_flag = splitted_strippeable_flags_set:has(flag)
                    break
                elseif flag:startswith("/" .. _flag) or flag:startswith("-" .. _flag) then
                    strip = true
                    break
                end
            end
        end

        if not strip then
            table.insert(output, flag)
        end
    end
    return output
end

-- extract defines from flags
function get_headerunit_key(target, sourcefile)

    local defines = target:get("defines") or {}
    local undefines = target:get("undefines") or {}
    local fileconfig = target:fileconfig(sourcefile)
    if fileconfig then
        table.join(defines, fileconfig.defines or {})
        table.join(undefines, fileconfig.undefines or {})
    end

    if #defines > 0 then
        defines = table.concat(defines, "-D")
    else
        defines = "<NO_DEFINES>"
    end
    if #undefines > 0 then
        undefines = table.concat(undefines, "-D")
    else
        undefines = "<NO_UNDEFINES>"
    end

    local key = hash.md5(bytes(defines .. undefines))
    return key
end

-- get bmi extension
function get_bmi_extension(target)
    return _support(target).get_bmi_extension()
end

-- get bmi path
-- @see https://github.com/xmake-io/xmake/issues/4063
function get_bmi_path(bmifile)
    bmifile = bmifile:gsub(":", "_PARTITION_")
    return path.normalize(bmifile)
end

-- has module extension? e.g. *.mpp, ...
function has_module_extension(sourcefile, opt)

    opt = opt or {}
    local modulexts = _g.modulexts
    if modulexts == nil then
        modulexts = hashset.of(".mpp", ".mxx", ".cppm", ".ixx")
        _g.modulexts = modulexts
    end
    local extension = opt.extension or path.extension(sourcefile)
    return modulexts:has(extension:lower())
end

-- this target contains module files?
function contains_modules(target)

    -- we can not use `"c++.build.modules.builder"`, because it contains sourcekind/cxx.
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

-- mark that a module scan artifacts and bmifile are reused from an other target
function set_reused(target, from, sourcefile)
    memcache():set2(target:fullname() .. "/modules/" .. sourcefile, "reuse", from)
    if option.get("diagnosis") then
        print("<" .. target:fullname() .. ">", "reuse", sourcefile, "from", "<" .. from:fullname() .. ">")
    end
end

-- query if a module scan artifacts and bmifile are reused from an other target
function is_reused(target, sourcefile)
    local from = memcache():get2(target:fullname() .. "/modules/" .. sourcefile, "reuse")
    return from and true or false, from
end

-- query if a module is public
function is_public(target, sourcefile)
    local fileconfig = target:fileconfig(sourcefile)
    return fileconfig and fileconfig.public or false
end

-- query if a module is external
function is_external(target, sourcefile)
    local fileconfig = target:fileconfig(sourcefile)
    local external = fileconfig and fileconfig.external
    return external or false
end

-- query if a module is external
function is_bmionly(target, sourcefile)
    local fileconfig = target:fileconfig(sourcefile)
    return fileconfig and fileconfig.bmionly or false
end

-- query if a module can be culled
function can_be_culled(target, sourcefile)

    local can_cull = target:policy("build.c++.modules.culling")
    local fileconfig = target:fileconfig(sourcefile)
    local _, stdmodules_set = get_stdmodules(target)
    local is_stdmodule = stdmodules_set and stdmodules_set:has(sourcefile) or false
    local public = target:kind() == "moduleonly" and not is_stdmodule
    if fileconfig then
        public = fileconfig.public
        if fileconfig.cull ~= nil then
            can_cull = can_cull and fileconfig.cull
        end
    end
    return can_cull and not public
end

-- load module infos
function load_moduleinfos(target, sourcebatch)

    local moduleinfos
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local reused, from = is_reused(target, sourcefile)
        local dependfile = reused and from:dependfile(sourcefile) or target:dependfile(sourcefile)
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

function find_quote_header_file(sourcefile, file)
    local p = path.join(path.directory(path.absolute(sourcefile, project.directory())), file)
    assert(os.isfile(p), "\"%s\" not found", p)
    return p
end

function find_angle_header_file(target, file)

    local headerpaths = _support(target).toolchain_includedirs(target)
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
    assert(p, "<%s> not found!", file)
    return p
end

-- get stdmodules
function get_stdmodules(target)

    local stdmodules = memcache():get("c++.modules.stdmodules")
    local stdmodules_set = memcache():get("c++.modules.stdmodules_set")
    if not stdmodules or not stdmodules_set then
        stdmodules =  _support(target).get_stdmodules(target)
        stdmodules_set = hashset.from(stdmodules or {})
        memcache():set("c++.modules.stdmodules", stdmodules)
        memcache():set("c++.modules.stdmodules_set", stdmodules_set)
    end
    return stdmodules, stdmodules_set
end

-- get memcache
function memcache()
    return _memcache.cache("cxxmodules")
end

-- get localcache
function localcache()
    return _localcache.cache("cxxmodules")
end

-- get modules cache directory
function modules_cachedir(target, opt)

    assert(opt and (opt.interface ~= nil or opt.headerunit or opt.scan))
    local type
    if opt.headerunit then
        type = "headerunits"
    elseif opt.interface then
        type = "interfaces"
    elseif opt.scan then
        type = "scans"
    else 
        type = "implementation"
    end
    local cachedir = path.join(target:autogendir(), "rules", "bmi", "cache", type)
    if opt.mkdir and not os.isdir(cachedir) then
        os.mkdir(cachedir)
    end
    return cachedir
end

function get_modulehash(sourcefile)
    return hash.uuid(sourcefile):split("-", {plain = true})[1]:lower()
end

function get_metafile(target, module)
    -- metafile are only for named modules
    local outputdir = get_outputdir(target, module.sourcefile, {interface = module.interface or false})
    return path.join(outputdir, path.filename(module.sourcefile) .. ".meta-info")
end

function get_outputdir(target, sourcefile, opt)

    local cachedir = modules_cachedir(target, opt)
    local modulehash = opt.key or get_modulehash(sourcefile)
    local outputdir = path.join(cachedir, modulehash)
    if not os.exists(outputdir) then
        os.mkdir(outputdir)
    end
    return outputdir
end

function add_installfiles_for_modules(target, modules)

    local sourcebatch = target:sourcebatches()["c++.build.modules.install"]
    if sourcebatch and sourcebatch.sourcefiles then
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local fileconfig = target:fileconfig(sourcefile)
            local install = fileconfig and fileconfig.public or false
            if install then
                local modulehash = get_modulehash(sourcefile)
                local prefixdir = path.join("modules", modulehash)
                target:add("installfiles", sourcefile, {prefixdir = prefixdir})
                local metafile = get_metafile(target, modules[sourcefile])
                if os.exists(metafile) then
                    target:add("installfiles", metafile, {prefixdir = prefixdir})
                end
            end
        end
    end
end

