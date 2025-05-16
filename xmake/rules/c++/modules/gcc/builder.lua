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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki, Arthapz
-- @file        gcc/builder.lua
--

-- imports
import("core.base.json")
import("core.base.option")
import("core.base.bytes")
import("core.base.semver")
import("utils.progress")
import("private.action.build.object", {alias = "objectbuilder"})
import("core.tool.compiler")
import("core.project.config")
import("core.project.depend")
import("support")
import(".mapper")
import(".builder", {inherit = true})

-- get flags for building a headerunit
function _make_headerunitflags(target, headerunit_mapper, headerunit)
    local module_headerflag = support.get_moduleheaderflag(target)
    local module_mapperflag = support.get_modulemapperflag(target)
    assert(module_headerflag, "compiler(gcc): does not support c++ header units!")

    local headertype = (headerunit.method == "include-angle") and "system" or "user"
    local includedir = headertype == "user" and "-I" .. path.directory(headerunit.sourcefile)
    return table.join(includedir and {includedir} or {},
                      {"-x", "c++-" .. headertype .. "-header",
                      module_mapperflag .. headerunit_mapper,
                     module_headerflag .. headertype})
end

-- do compile
function _compile(target, flags, module, opt)

    opt = opt or {}
    local sourcefile = opt.headerunit and path.filename(module.sourcefile) or module.sourcefile
    local outputfile = opt.headerunit and module.bmifile or module.objectfile
    local dryrun = option.get("dry-run")
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join(compflags or {}, flags or {})

    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, rawargs = true})
    end
    local mapper_str
    if option.get("diagnosis") then
        if opt.headerunit then
            mapper_str = format("\n${dim color.warning}mapper file for %s (%s) --------\n%s\n--------", sourcefile, module.name, io.readfile(opt.mapper_file):trim())
        elseif module.name  then
            mapper_str = format("\n${dim color.warning}mapper file for %s (%s) --------\n%s\n--------", module.name, sourcefile, io.readfile(opt.mapper_file):trim())
        else
            mapper_str = format("\n${dim color.warning}mapper file for %s --------\n%s\n--------", sourcefile, io.readfile(opt.mapper_file):trim())
        end
    end
    show_progress(target, module, table.join(opt, {cmd = cmd, suffix = mapper_str}))

    -- do compile
    if not dryrun then
        assert(compinst:compile(sourcefile, outputfile, {target = target, compflags = flags}))
    end
end

-- do compile for batchcmds
-- @note we need to use batchcmds:compilev to translate paths in compflags for generator, e.g. -Ixx
function _batchcmds_compile(batchcmds, target, flags, module, opt)
    local sourcefile = opt.headerunit and path.filename(module.sourcefile) or module.sourcefile
    local outputfile = opt.headerunit and module.bmifile or module.objectfile
    local compinst = target:compiler("cxx")
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})
    flags = table.join("-c", compflags or {}, flags or {}, {"-o", outputfile, sourcefile})

    -- trace
    local cmd
    if option.get("verbose") then
        cmd = "\n" .. compinst:compcmd(sourcefile, outputfile, {target = target, compflags = flags, rawargs = true})
    end
    local mapper_str
    if option.get("diagnosis") then
        if opt.headerunit then
            mapper_str = format("\n${dim color.warning}mapper file for %s (%s) --------\n%s\n--------", sourcefile, module.name, io.readfile(opt.mapper_file):trim())
        elseif module.name  then
            mapper_str = format("\n${dim color.warning}mapper file for %s (%s) --------\n%s\n--------", module.name, sourcefile, io.readfile(opt.mapper_file):trim())
        else
            mapper_str = format("\n${dim color.warning}mapper file for %s --------\n%s\n--------", sourcefile, io.readfile(opt.mapper_file):trim())
        end
    end
    show_progress(target, module, table.join(opt, {cmd = cmd, suffix = mapper_str, batchcmds = batchcmds}))

    -- do compile
    batchcmds:compilev(flags, {compiler = compinst, sourcekind = "cxx", verbose = false})
end

function _module_map_cachekey(target)
    local mode = config.mode()
    return target:fullname() .. "module_mapper" .. (mode or "")
end

-- generate a module mapper file for build a headerunit
function _generate_headerunit_modulemapper_file(target, headerunit)
    local mapper_path = _get_modulemapper_file(target, headerunit)
    local mapper_file = io.open(mapper_path, "wb")
    mapper_file:write("root " .. path.directory(headerunit.sourcefile) .. "\n")
    mapper_file:write(mapper_file, path.unix(headerunit.sourcefile) .. " " .. path.unix(path.absolute(headerunit.bmifile)) .. "\n")
    mapper_file:write("\n")
    mapper_file:close()
    return mapper_path
end

function _get_maplines(target, module)

    local maplines = {}
    if module.name then
        table.insert(maplines, module.name .. " " .. path.absolute(module.bmifile))
    end
    for dep_name, dep_module in table.orderpairs(module.deps) do
        local key = dep_name
        if dep_module.headerunit then
            key = dep_name .. dep_module.key
        end
        local dep_module_mapped = mapper.get(target, key)
        assert(dep_module_mapped, "module dependency %s required for %s not found", dep_name, module.name or module.sourcefile)
        local mapline
        local name = dep_name
        if dep_module_mapped.headerunit then
            name = dep_module_mapped.method == "include-angle" and dep_module_mapped.sourcefile or path.join("./", path.directory(module.sourcefile), dep_name)
        end
        mapline = path.unix(name) .. " " .. path.unix(path.absolute(dep_module_mapped.bmifile))
        table.insert(maplines, mapline)

        -- append deps
        if dep_module.deps then
            local deps = _get_maplines(target, {name = dep_module.name, deps = dep_module.deps, sourcefile = dep_module.sourcefile})
            table.join2(maplines, deps)
        end
    end

    -- remove duplicates
    return table.unique(maplines)
end

function _get_modulemapper_file(target, module)
    return path.join(os.tmpdir(), hash.md5(bytes(target:fullname() .. "/" .. module.sourcefile)), path.filename(module.sourcefile) .. ".mapper.txt")
end

-- generate a module mapper file for build a module
-- e.g
-- /usr/include/c++/11/iostream build/.gens/stl_headerunit/linux/x86_64/release/stlmodules/cache/iostream.gcm
-- hello build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm
--
function _generate_modulemapper_file(target, module)
    local maplines = _get_maplines(target, module)
    local mapper_path = _get_modulemapper_file(target, module)
    if os.isfile(mapper_path) then
        os.rm(mapper_path)
    end
    local mapper_content = {}
    table.insert(mapper_content, "root " .. path.unix(os.projectdir()))
    for _, mapline in ipairs(maplines) do
        table.insert(mapper_content, mapline)
    end
    mapper_content = table.concat(mapper_content, "\n") .. "\n"
    if not os.isfile(mapper_path) or io.readfile(mapper_path, {encoding = "binary"}) ~= mapper_content then
        io.writefile(mapper_path, mapper_content, {encoding = "binary"})
    end
    return mapper_path
end

-- build module file for batchjobs / jobgraph
function make_module_job(target, module, opt)

    local module_mapperflag = support.get_modulemapperflag(target)
    local module_onlyflag = support.get_moduleonlyflag(target)
    local module_flag = support.get_modulesflag(target)
    local dryrun = option.get("dry-run")

    -- generate and append module mapper file
    local module_mapper
    if module.deps then
        module_mapper = _get_modulemapper_file(target, module)
        target:fileconfig_add(module.sourcefile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
    end

    local build = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build then
        if not dryrun then
            local objectdir = path.directory(module.objectfile)
            if not os.isdir(objectdir) then
                os.mkdir(objectdir)
            end
            if module.bmifile then
                local bmidir = path.directory(module.bmifile)
                if not os.isdir(bmidir) then
                    os.mkdir(bmidir)
                end
            end
        end

        if module.deps then
            _generate_modulemapper_file(target, module)
        end

        local flags = {"-x", "c++"}
        if support.has_module_extension(module.sourcefile) or module.name then
            if bmi then
                if objectfile then
                    table.insert(flags, module_flag)
                else
                    table.insert(flags, module_flag)
                    table.insert(flags, module_onlyflag)
                end
            end
            _compile(target, flags, module, table.join(opt or {}, {mapper_file = module_mapper}))
        else
            os.tryrm(module.objectfile) -- force rebuild for .cpp files
        end
    end
end

-- build module file for batchcmds
function make_module_buildcmds(target, batchcmds, module, opt)

    local module_mapperflag = support.get_modulemapperflag(target)
    local module_onlyflag = support.get_moduleonlyflag(target)
    local module_flag = support.get_modulesflag(target)

    local module_mapper
    if module.deps then
        module_mapper = _get_modulemapper_file(target, module)
        target:fileconfig_add(module.sourcefile, {force = {cxxflags = {module_mapperflag .. module_mapper}}})
    end

    -- generate and append module mapper file
    local build = should_build(target, module)
    local bmi = opt and opt.bmi
    local objectfile = opt and opt.objectfile

    if build then
        local objectdir = path.directory(module.objectfile)
        batchcmds:mkdir(objectdir)
        if module.bmifile then
            local bmidir = path.directory(module.bmifile)
            batchcmds:mkdir(bmidir)
        end

        if module.deps then
            _generate_modulemapper_file(target, module)
        end

        local flags = {"-x", "c++"}
        if support.has_module_extension(module.sourcefile) or module.name then
            if bmi then
                if objectfile then
                    table.insert(flags, module_flag)
                else
                    table.insert(flags, module_flag)
                    table.insert(flags, module_onlyflag)
                end
            end
            _batchcmds_compile(batchcmds, target, flags, module, table.join(opt, {batchcmds = batchcmds, mapper_file = module_mapper}))
        else
            batchcmds:rm(module.objectfile) -- force rebuild for .cpp files
        end
    end
    return os.mtime(module.objectfile)
end

-- build headerunit file for batchjobs / jobgraph
function make_headerunit_job(target, headerunit, opt)
    local build = should_build(target, headerunit)
    if build then
        local headerunit_mapper = _generate_headerunit_modulemapper_file(target, headerunit)
        _compile(target,
                 _make_headerunitflags(target, headerunit_mapper, headerunit),
                 headerunit, table.join(opt, {mapper_file = headerunit_mapper, headerunit = true}))
    end
end

-- build headerunit file for batchcmds
function make_headerunit_buildcmds(target, batchcmds, headerunit, opt)
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = headerunit.sourcefile, target = target, sourcekind = "cxx"})
    local depvalues = {compinst:program(), compflags}

    local build = should_build(target, headerunit)
    if build then
        local headerunit_mapper = _generate_headerunit_modulemapper_file(target, headerunit)
        _batchcmds_compile(batchcmds, target,
                     _make_headerunitflags(target, headerunit_mapper, headerunit),
                     headerunit, table.join(opt, {mapper_file = headerunit_mapper, headerunit = true}))
        batchcmds:add_depfiles(headerunit.sourcefile)
    end
    batchcmds:add_depvalues(depvalues)
end

