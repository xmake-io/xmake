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
-- @file        amalgamate.lua
--

-- imports
import("core.base.option")
import("core.base.graph")
import("core.project.config")
import("core.project.task")
import("core.project.project")
import("private.detect.check_targetname")

-- the options
local options =
{
    {'u', "uniqueid",  "kv", nil, "Set the unique id."       },
    {'o', "outputdir", "kv", nil, "Set the output directory."},
    {nil, "target",    "v",  nil, "The target name."         }
}

-- get include files
function _get_include_files(target, filepath)
    local includes = {}
    local sourcecode = io.readfile(filepath)
    sourcecode = sourcecode:gsub("/%*.-%*/", "")
    sourcecode = sourcecode:gsub("//.-\n", "\n")
    sourcecode:gsub("#include%s+\"(.-)\"", function (include)
        table.insert(includes, include)
    end)
    includes = table.unique(includes)

    local includefiles = {}
    local filedir = path.directory(filepath)
    local includedirs = table.join(filedir, target:get("includedirs"))
    for _, include in ipairs(includes) do
        local result
        for _, includedir in ipairs(includedirs) do
            local includefile = path.join(includedir, include)
            if os.isfile(includefile) then
                includefile = path.normalize(path.absolute(includefile, os.projectdir()))
                result = includefile
                break
            end
        end
        if result then
            table.insert(includefiles, result)
        else
            wprint("#include \"%s\" not found in %s", include, filepath)
        end
    end
    return includefiles
end

-- generate include graph
function _generate_include_graph(target, inputpaths, gh, marked)
    for _, inputpath in ipairs(inputpaths) do
        if not marked[inputpath] then
            marked[inputpath] = true
            local includefiles = _get_include_files(target, inputpath)
            for _, includefile in ipairs(includefiles) do
                gh:add_edge(inputpath, includefile)
            end
            if includefiles and #includefiles > 0 then
                _generate_include_graph(target, includefiles, gh, marked)
            end
        end
    end
end

-- generate file
function _generate_file(target, inputpaths, outputpath, uniqueid)

    -- generate include graph
    local gh = graph.new(true)
    for idx, inputpath in ipairs(inputpaths) do
        inputpath = path.normalize(path.absolute(inputpath, os.projectdir()))
        inputpaths[idx] = inputpath
        gh:add_edge("__root__", inputpath)
    end
    _generate_include_graph(target, inputpaths, gh, {})

    -- sort file paths and remove root path
    local filepaths = gh:topological_sort()
    table.remove(filepaths, 1)

    -- generate amalgamate file
    local outputfile = io.open(outputpath, "w")
    for _, filepath in irpairs(filepaths) do
        cprint("  ${color.dump.reference}+${clear} %s", filepath)
        if uniqueid then
            outputfile:print("#define %s %s", uniqueid, "unity_" .. hash.uuid():split("-", {plain = true})[1])
        end
        outputfile:write(io.readfile(filepath))
        if uniqueid then
            outputfile:print("#undef %s", uniqueid)
        end
    end
    outputfile:close()
    cprint("${bright}%s generated!", outputpath)
end

-- generate code
function _generate_amalgamate_code(target, opt)

    -- only for library/binary
    if not target:is_library() and not target:is_binary() then
        return
    end

    -- generate source code
    local outputdir = opt.outputdir
    local uniqueid = opt.uniqueid
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local rulename = sourcebatch.rulename
        if rulename == "c.build" or rulename == "c++.build" then
            local outputpath = path.join(outputdir, target:name() .. (sourcekind == "cxx" and ".cpp" or ".c"))
            _generate_file(target, sourcebatch.sourcefiles, outputpath, uniqueid)
        end
    end

    -- generate header file
    local srcheaders = target:headerfiles(includedir)
    if srcheaders and #srcheaders > 0 then
        local outputpath = path.join(outputdir, target:name() .. ".h")
        _generate_file(target, srcheaders, outputpath, uniqueid)
    end
end

-- generate amalgamate code
--
-- https://github.com/xmake-io/xmake/issues/1438
--
function main(...)

    -- parse arguments
    local argv = table.pack(...)
    local args = option.parse(argv, options, "Generate amalgamate code.",
                                             "",
                                             "Usage: xmake l cli.amalgamate [options]")

    -- config first
    task.run("config")

    -- generate amalgamate code
    args.outputdir = args.outputdir or config.buildir()
    if args.target then
        local target = assert(check_targetname(args.target))
        _generate_amalgamate_code(target, args)
    else
        for _, target in ipairs(project.ordertargets()) do
            _generate_amalgamate_code(target, args)
        end
    end
end
