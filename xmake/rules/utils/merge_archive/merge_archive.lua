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
-- @file        merge_archive.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.depend")
import("core.project.target", {alias = "project_target"})
import("private.utils.progress")
import("core.tool.toolchain")
import("private.tools.vstool")

-- extract the static library for ar
function _extract_for_ar(program, libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- get the absolute path of this library
    libraryfile = path.absolute(libraryfile)

    -- extract it
    os.runv(program, {"-x", libraryfile}, {curdir = objectdir})

    -- check repeat object name
    local repeats = {}
    local objectfiles = os.iorunv(program, {"-t", libraryfile})
    for _, objectfile in ipairs(objectfiles:split('\n')) do
        if repeats[objectfile] then
            raise("object name(%s) conflicts in library: %s", objectfile, libraryfile)
        end
        repeats[objectfile] = true
    end
end

-- extract the static library for msvc/lib
function _extract_for_msvclib(program, libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- get runenvs for msvc
    local runenvs
    local msvc = toolchain.load("msvc")
    if msvc then
        runenvs = msvc:runenvs()
    end

    -- list object files
    local objectfiles = vstool.iorunv(program, {"-nologo", "-list", libraryfile}, {envs = runenvs})

    -- extrace all object files
    for _, objectfile in ipairs(objectfiles:split('\n')) do

        -- is object file?
        if objectfile:find("%.obj") then

            -- make the outputfile
            local outputfile = path.translate(format("%s\\%s", objectdir, path.filename(objectfile)))

            -- repeat? rename it
            if os.isfile(outputfile) then
                for i = 0, 10 do
                    outputfile = path.translate(format("%s\\%d_%s", objectdir, i, path.filename(objectfile)))
                    if not os.isfile(outputfile) then
                        break
                    end
                end
            end

            -- extract it
            vstool.runv(program, {"-nologo", "-extract:" .. objectfile, "-out:" .. outputfile, libraryfile}, {envs = runenvs})
        end
    end
end

-- do extract
function _extract(target, libraryfile, objectdir)
    local program, toolname = target:tool("ex")
    if program and toolname then
        if toolname:find("ar") then
            _extract_for_ar(program, libraryfile, objectdir)
        elseif toolname == "lib" then
            _extract_for_msvclib(program, libraryfile, objectdir)
        end
    else
        raise("cannot extract %s, extractor not found!", libraryfile)
    end
end

-- main entry
function main (target, sourcebatch, opt)

    -- @note we cannot process archives in parallel because the current directory may be changed
    for i = 1, #sourcebatch.sourcefiles do

        -- get library source file
        local sourcefile_lib = sourcebatch.sourcefiles[i]

        -- get object directory of the archive file
        local objectdir = target:objectfile(sourcefile_lib) .. ".dir"

        -- load dependent info
        local dependfile = target:dependfile(objectdir)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectdir)}) then
            local objectfiles = os.files(path.join(objectdir, "**" .. project_target.filename("", "object")))
            table.join2(target:objectfiles(), objectfiles)
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}inserting.$(mode) %s", sourcefile_lib)

        -- extract the archive library
        os.tryrm(objectdir)
        _extract(target, sourcefile_lib, objectdir)

        -- add objectfiles
        local objectfiles = os.files(path.join(objectdir, "**" .. project_target.filename("", "object")))
        table.join2(target:objectfiles(), objectfiles)

        -- update files to the dependent file
        dependinfo.files = {}
        table.insert(dependinfo.files, sourcefile_lib)
        depend.save(dependinfo, dependfile)
    end
end

