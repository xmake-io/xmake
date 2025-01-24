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
-- @author      ruki
-- @file        build_module_file.lua
--

-- imports
import("lib.detect.find_tool")
import("utils.progress")
import("core.project.depend")
import("core.tool.compiler")

function find_user_outdir(fileconfig)
    -- user specified output path
    if fileconfig and fileconfig.swigflags then
        -- find -outdir path
        for i, par in ipairs(fileconfig.swigflags) do
            if par == "-outdir" then
                local dirpath = fileconfig.swigflags[i + 1]
                if os.isdir(dirpath) then
                    return dirpath
                end
            end
        end
    end
end

function jar_build(target, fileconfig, opt)
    local javac = assert(find_tool("javac"), "javac not found!")
    local jar = assert(find_tool("jar"), "jar not found!")

    local java_src_dir = path.join(target:autogendir(), "rules", "swig")
    local java_class_dir = java_src_dir

    local user_outdir = find_user_outdir(fileconfig)
    if user_outdir then
        java_src_dir = user_outdir
    end

    -- get java files
    local autogenfiles = os.files(path.join(java_src_dir, "*.java"))

    -- write file list
    local filelistname = path.join(java_src_dir, "buildlist.txt")
    local file = io.open(filelistname, "w")
    if file then
        for _, sourcebatch in ipairs(autogenfiles) do
            file:print(sourcebatch)
        end
        file:close()
    end

    -- compile to class file
    progress.show(opt.progress, "${color.build.object}compiling.javac %s class file", target:name())
    os.vrunv(javac.program, {"--release", "17", "-d", java_class_dir, "@" .. filelistname})

    -- generate jar file
    progress.show(opt.progress, "${color.build.object}compiling.jar %s", target:name() .. ".jar")
    os.vrunv(jar.program, {"-cf", path.join(java_src_dir, target:name() .. ".jar"), java_class_dir})

    os.tryrm(filelistname)
end

function swig_par(target, sourcefile, opt)
    -- get swig
    opt = opt or {}
    local swig = assert(find_tool("swig"), "swig not found!")
    local sourcefile_cx = path.join(target:autogendir(), "rules", "swig",
        path.basename(sourcefile) .. (opt.sourcekind == "cxx" and ".cpp" or ".c"))

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    local moduletype = assert(target:data("swig.moduletype"), "swig.moduletype not found!")
    local argv = {"-" .. moduletype, "-o", sourcefile_cx}
    if opt.sourcekind == "cxx" then
        table.insert(argv, "-c++")
    end
    local fileconfig = target:fileconfig(sourcefile)
    if fileconfig and fileconfig.swigflags then
        table.join2(argv, fileconfig.swigflags)
    end

    -- add includedirs
    local function _get_values_from_target(target, name)
        local values = {}
        for _, value in ipairs((target:get_from(name, "*"))) do
            table.join2(values, value)
        end
        return table.unique(values)
    end
    local pathmaps = {
        { "includedirs",    "includedir" },
        { "sysincludedirs", "includedir" },
        { "frameworkdirs",  "frameworkdir" }
    }
    for _, pathmap in ipairs(pathmaps) do
        for _, item in ipairs(_get_values_from_target(target, pathmap[1])) do
            table.join2(argv, "-I" .. item)
        end
    end

    table.insert(argv, sourcefile)
    return {
        argv = argv,
        objectfile = objectfile,
        swig = swig,
        sourcefile_cx = sourcefile_cx,
        moduletype = moduletype,
        fileconfig = fileconfig
    }
end

function swig_build_cmd(target, batchcmds, sourcefile, opt, pars)
    local par = swig_par(target, sourcefile, opt)

    local objectfile = par.objectfile
    local argv = par.argv
    local swig = par.swig
    local sourcefile_cx = par.sourcefile_cx
    local moduletype = par.moduletype
    local fileconfig = par.fileconfig

    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.swig.%s %s", moduletype, sourcefile)
    batchcmds:mkdir(path.directory(sourcefile_cx))
    batchcmds:vrunv(swig.program, argv)
    batchcmds:compile(sourcefile_cx, objectfile)

    -- add deps
    batchcmds:add_depfiles(sourcefile)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end

function swig_build_file(target, sourcefile, opt, par)
    local par = swig_par(target, sourcefile, opt)

    local objectfile = par.objectfile
    local argv = par.argv
    local swig = par.swig
    local sourcefile_cx = par.sourcefile_cx
    local moduletype = par.moduletype
    local fileconfig = par.fileconfig

    local dependfile = target:dependfile(objectfile)
    local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile),
                                          values = argv
                                          }) then
        return
    end

    progress.show(opt.progress, "${color.build.object}compiling.swig.%s %s", moduletype, sourcefile)
    os.mkdir(path.directory(sourcefile_cx))

    -- gen swig depend file , same with gcc .d
    local swigdep = os.tmpfile()
    local argv2 = {"-MMD", "-MF", swigdep}
    table.join2(argv2, argv)

    -- swig generate file and depend file
    os.vrunv(swig.program, argv2)
    compiler.compile(sourcefile_cx, objectfile, {target = target})

    -- update depend file
    local deps = io.readfile(swigdep, {continuation = "\\"})
    os.tryrm(swigdep)
    dependinfo.files = {sourcefile}
    dependinfo.depfiles_format = "gcc"
    dependinfo.depfiles = deps
    dependinfo.values = argv
    depend.save(dependinfo, target:dependfile(objectfile))

    -- jar build
    local buildjar = target:extraconf("rules", "swig.c", "buildjar") or target:extraconf("rules", "swig.cpp", "buildjar")
    if moduletype == "java" and buildjar then
        jar_build(target, fileconfig, opt)
    end
end
