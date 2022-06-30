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
-- @file        unity_build.lua
--

-- imports
import("core.project.depend")

function _merge_unityfile(target, sourcefile_unity, sourcefiles, opt)
    local dependfile = target:dependfile(sourcefile_unity)
    depend.on_changed(function ()

        -- trace
        vprint("generating.unityfile %s", sourcefile_unity)

        -- do merge
        local uniqueid = target:data("unity_build.uniqueid")
        local unityfile = io.open(sourcefile_unity, "w")
        for _, sourcefile in ipairs(sourcefiles) do
            sourcefile = path.absolute(sourcefile)
            sourcefile_unity = path.absolute(sourcefile_unity)
            sourcefile = path.relative(sourcefile, path.directory(sourcefile_unity))
            if uniqueid then
                unityfile:print("#define %s %s", uniqueid, "unity_" .. hash.uuid():split("-", {plain = true})[1])
            end
            unityfile:print("#include \"%s\"", sourcefile)
            if uniqueid then
                unityfile:print("#undef %s", uniqueid)
            end
        end
        unityfile:close()

    end, {dependfile = dependfile, files = sourcefiles})
end

function generate_unityfiles(target, sourcebatch, opt)
    local unity_batch = target:data("unity_build.unity_batch." .. sourcebatch.rulename)
    if unity_batch then
        for _, sourcefile_unity in ipairs(sourcebatch.sourcefiles) do
            local sourceinfo = unity_batch[sourcefile_unity]
            if sourceinfo then
                local sourcefiles = sourceinfo.sourcefiles
                if sourcefiles then
                    _merge_unityfile(target, sourcefile_unity, sourcefiles, opt)
                end
            end
        end
    end
end

-- use unity build
--
-- e.g.
-- add_rules("c++.unity_build", {batchsize = 2})
-- add_files("src/*.c", "src/*.cpp", {unity_ignored = true})
-- add_files("src/foo/*.c", {unity_group = "foo"})
-- add_files("src/bar/*.c", {unity_group = "bar"})
--
function main(target, sourcebatch)

    -- we cannot generate unity build files in project generator
    if os.getenv("XMAKE_IN_PROJECT_GENERATOR") then
        return
    end

    -- get unit batch sources
    local extraconf = target:extraconf("rules", sourcebatch.sourcekind == "cxx" and "c++.unity_build" or "c.unity_build")
    local batchsize = extraconf and extraconf.batchsize
    local uniqueid = extraconf and extraconf.uniqueid
    local id = 1
    local count = 0
    local unity_batch = {}
    local sourcefiles = {}
    local objectfiles = {}
    local dependfiles = {}
    local sourcedir = path.join(target:autogendir({root = true}), target:plat(), "unity_build")
    for idx, sourcefile in pairs(sourcebatch.sourcefiles) do
        local sourcefile_unity
        local objectfile = sourcebatch.objectfiles[idx]
        local dependfile = sourcebatch.dependfiles[idx]
        local fileconfig = target:fileconfig(sourcefile)
        if fileconfig and fileconfig.unity_group then
            sourcefile_unity = path.join(sourcedir, "unity_group_" .. fileconfig.unity_group .. path.extension(sourcefile))
        elseif (fileconfig and fileconfig.unity_ignored) or (batchsize and batchsize <= 1) then
            -- we do not add these files to unity file
            table.insert(sourcefiles, sourcefile)
            table.insert(objectfiles, objectfile)
            table.insert(dependfiles, dependfile)
        else
            if batchsize and count >= batchsize then
                id = id + 1
                count = 0
            end
            sourcefile_unity = path.join(sourcedir, "unity_" .. tostring(id) .. path.extension(sourcefile))
            count = count + 1
        end
        if sourcefile_unity then
            local sourceinfo = unity_batch[sourcefile_unity]
            if not sourceinfo then
                sourceinfo = {}
                sourceinfo.objectfile = target:objectfile(sourcefile_unity)
                sourceinfo.dependfile = target:dependfile(sourceinfo.objectfile)
                sourceinfo.sourcefile1 = sourcefile
                sourceinfo.objectfile1 = objectfile
                sourceinfo.dependfile1 = dependfile
                unity_batch[sourcefile_unity] = sourceinfo
            end
            sourceinfo.sourcefiles = sourceinfo.sourcefiles or {}
            table.insert(sourceinfo.sourcefiles, sourcefile)
        end
    end

    -- use unit batch
    for _, sourcefile_unity in ipairs(table.orderkeys(unity_batch)) do
        local sourceinfo = unity_batch[sourcefile_unity]
        if #sourceinfo.sourcefiles > 1 then
            table.insert(sourcefiles, sourcefile_unity)
            table.insert(objectfiles, sourceinfo.objectfile)
            table.insert(dependfiles, sourceinfo.dependfile)
        else
            table.insert(sourcefiles, sourceinfo.sourcefile1)
            table.insert(objectfiles, sourceinfo.objectfile1)
            table.insert(dependfiles, sourceinfo.dependfile1)
        end
    end
    sourcebatch.sourcefiles = sourcefiles
    sourcebatch.objectfiles = objectfiles
    sourcebatch.dependfiles = dependfiles

    -- save unit batch
    target:data_set("unity_build.uniqueid", uniqueid)
    target:data_set("unity_build.unity_batch." .. sourcebatch.rulename, unity_batch)
end
