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

function main(target, sourcefile, opt)
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
    local argv = { "-" .. moduletype, "-o", sourcefile_cx }
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
    depend.on_changed(function ()
        progress.show(opt.progress, "${color.build.object}compiling.swig.%s %s", moduletype, sourcefile)
        os.mkdir(path.directory(sourcefile_cx))
        os.vrunv(swig.program, argv)
        compiler.compile(sourcefile_cx, objectfile, {target = target})

        local buildjar = target:extraconf("rules", "swig.c", "buildjar") or target:extraconf("rules", "swig.cpp", "buildjar")
        if moduletype == "java" and buildjar then
            local javac = assert(find_tool("javac"), "javac not found!")
            local jar = assert(find_tool("jar"), "jar not found!")

            local java_src_dir = path.join(target:autogendir(), "rules", "swig")
            local jar_dst_dir = path.join(target:autogendir(), "rules", "swig")

            -- user specified output path
            if fileconfig and fileconfig.swigflags then
                -- find -outdir path
                local idx = -1
                for i , par in pairs(fileconfig.swigflags) do
                    if par == "-outdir" then
                        idx = i
                    end
                end

                if idx > 0 then
                    java_src_dir = fileconfig.swigflags[idx + 1]
                end
            end

            -- get java files
            local autogenfiles = os.files(path.join(java_src_dir, "*.java"))

            -- write file list
            local filelistname = os.tmpfile()
            local file = io.open(filelistname, "w")
            if file then
                for _, sourcebatch in pairs(autogenfiles) do
                    file:print(sourcebatch)
                end
                file:close()
            end

            -- compile to class file
            progress.show(opt.progress, "${color.build.object}compiling.javac %s class file", target:name())
            os.vrunv(javac.program, {"--release", "17", "-d", jar_dst_dir , "@"..filelistname})

            -- generate jar file
            progress.show(opt.progress, "${color.build.object}compiling.jar %s", target:name()..".jar")
            os.vrunv(jar.program, {"-cf" , path.join(java_src_dir , target:name()..".jar") , jar_dst_dir})
        end

    end, {dependfile = target:dependfile(objectfile),
          lastmtime = os.mtime(objectfile),
          files = sourcefile,
          values = argv,
          changed = target:is_rebuilt()})
end
