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
import("core.project.config")
import("core.project.task")
import("core.project.project")

-- the options
local options =
{
    {'u', "uniqueid",  "kv", nil, "Set the unique id."       },
    {'o', "outputdir", "kv", nil, "Set the output directory."},
    {nil, "target",    "v",  nil, "The target name."         }
}

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
        local sourcekind = sourcebatch.sourcekind
        if sourcekind == "cc" or sourcekind == "cxx" then
            local outputpath = path.join(outputdir, target:name() .. (sourcekind == "cxx" and ".cpp" or ".c"))
            local outputfile = io.open(outputpath, "w")
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                if uniqueid then
                    outputfile:print("#define %s %s", uniqueid, "unity_" .. hash.uuid():split("-", {plain = true})[1])
                end
                outputfile:write(io.readfile(sourcefile))
                if uniqueid then
                    outputfile:print("#undef %s", uniqueid)
                end
            end
            outputfile:close()
            cprint("${bright}%s generated!", outputpath)
        end
    end

    -- generate header file
    local srcheaders = target:headerfiles(includedir)
    if srcheaders and #srcheaders > 0 then
        local outputpath = path.join(outputdir, target:name() .. ".h")
        local outputfile = io.open(outputpath, "w")
        for _, srcheader in ipairs(srcheaders) do
            if uniqueid then
                outputfile:print("#define %s %s", uniqueid, "unity_" .. hash.uuid():split("-", {plain = true})[1])
            end
            outputfile:write(io.readfile(srcheader))
            if uniqueid then
                outputfile:print("#undef %s", uniqueid)
            end
        end
        outputfile:close()
        cprint("${bright}%s generated!", outputpath)
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
        _generate_amalgamate_code(args.target, args)
    else
        for _, target in ipairs(project.ordertargets()) do
            _generate_amalgamate_code(target, args)
        end
    end
end
