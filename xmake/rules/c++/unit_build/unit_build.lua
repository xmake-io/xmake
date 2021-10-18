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
-- @file        unit_build.lua
--

-- imports
import("core.project.depend")

function _merge_unitfile(target, sourcefile_unit, sourcefiles, opt)
    local dependfile = target:dependfile(sourcefile_unit)
    depend.on_changed(function ()

        -- trace
        vprint("generating.unitfile %s", sourcefile_unit)

        -- do merge
        local unitfile = io.open(sourcefile_unit, "w")
        for _, sourcefile in ipairs(sourcefiles) do
            sourcefile = path.absolute(sourcefile)
            sourcefile_unit = path.absolute(sourcefile_unit)
            sourcefile = path.relative(sourcefile, path.directory(sourcefile_unit))
            unitfile:print("#include \"%s\"", sourcefile)
        end
        unitfile:close()

    end, {dependfile = dependfile, files = sourcefiles})
end

function generate_unitfiles(target, sourcebatch, opt)
    local unitbatch = target:data("unit_build.unitbatch." .. sourcebatch.rulename)
    if unitbatch then
        for _, sourcefile_unit in ipairs(sourcebatch.sourcefiles) do
            local sourceinfo = unitbatch[sourcefile_unit]
            if sourceinfo then
                local sourcefiles = sourceinfo.sourcefiles
                if sourcefiles then
                    _merge_unitfile(target, sourcefile_unit, sourcefiles, opt)
                end
            end
        end
    end
end

-- use unit build
--
-- e.g.
-- add_rules("c++.unit_build", {batchsize = 2})
-- add_files("src/*.c", "src/*.cpp", {unit_ignored = true})
-- add_files("src/foo/*.c", {unit_group = "foo"})
-- add_files("src/bar/*.c", {unit_group = "bar"})
--
function main(target, sourcebatch)

    -- get unit batch sources
    local extraconf = target:extraconf("rules", "c++.unit_build")
    local batchsize = extraconf and extraconf.batchsize
    local id = 1
    local count = 0
    local unitbatch = {}
    local sourcefiles = {}
    local objectfiles = {}
    local dependfiles = {}
    local sourcedir = path.join(target:autogendir({root = true}), "unit_build")
    for idx, sourcefile in pairs(sourcebatch.sourcefiles) do
        local sourcefile_unit
        local objectfile = sourcebatch.objectfiles[idx]
        local dependfile = sourcebatch.dependfiles[idx]
        local fileconfig = target:fileconfig(sourcefile)
        if fileconfig and fileconfig.unit_group then
            sourcefile_unit = path.join(sourcedir, "unit_" .. fileconfig.unit_group .. path.extension(sourcefile))
        elseif fileconfig and fileconfig.unit_ignored then
            -- we do not add these files to unit file
            table.insert(sourcefiles, sourcefile)
            table.insert(objectfiles, objectfile)
            table.insert(dependfiles, dependfile)
        else
            if batchsize and count > batchsize then
                id = id + 1
            end
            sourcefile_unit = path.join(sourcedir, "unit_" .. hash.uuid(tostring(id)):split("-", {plain = true})[1] .. path.extension(sourcefile))
            count = count + 1
        end
        if sourcefile_unit then
            local sourceinfo = unitbatch[sourcefile_unit]
            if not sourceinfo then
                sourceinfo = {}
                sourceinfo.objectfile = target:objectfile(sourcefile_unit)
                sourceinfo.dependfile = target:dependfile(sourceinfo.objectfile)
                unitbatch[sourcefile_unit] = sourceinfo
            end
            sourceinfo.sourcefiles = sourceinfo.sourcefiles or {}
            table.insert(sourceinfo.sourcefiles, sourcefile)
        end
    end

    -- use unit batch
    for sourcefile_unit, sourceinfo in pairs(unitbatch) do
        table.insert(sourcefiles, sourcefile_unit)
        table.insert(objectfiles, sourceinfo.objectfile)
        table.insert(dependfiles, sourceinfo.dependfile)
    end
    sourcebatch.sourcefiles = sourcefiles
    sourcebatch.objectfiles = objectfiles
    sourcebatch.dependfiles = dependfiles

    -- save unit batch
    target:data_set("unit_build.unitbatch." .. sourcebatch.rulename, unitbatch)
end
