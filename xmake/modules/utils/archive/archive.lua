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
-- @file        archive.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("extension", {alias = "get_archive_extension"})

-- archive archivefile using zip
function _archive_using_zip(archivefile, inputdir, extension, opt)

    -- find zip
    local zip = find_tool("zip")
    if not zip then
        return false
    end

    -- init argv
    local argv = {archivefile}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    if opt.excludes then
        table.insert(argv, "-x")
        for _, exclude in ipairs(opt.excludes) do
            table.insert(argv, exclude)
        end
    end
    if opt.includes then
        table.insert(argv, "-i")
        for _, include in ipairs(opt.includes) do
            table.insert(argv, include)
        end
    end
    local compress = opt.compress
    if compress then
        if compress == "faster" or compress == "fastest" then
            table.insert(argv, "-1")
        elseif compress == "better" or compress == "best" then
            table.insert(argv, "-9")
        end
    end
    if opt.recurse then
        table.insert(argv, "-r")
    end
    table.insert(argv, inputdir)

    -- archive it
    os.vrunv(zip.program, argv, {curdir = opt.curdir})
    return true
end

-- archive archivefile using 7z
function _archive_using_7z(archivefile, inputdir, extension, opt)

    -- find 7z
    local z7 = find_tool("7z")
    if not z7 then
        return false
    end

    -- init argv
    local argv = {"a", archivefile, "-y"}
    local excludesfile
    if opt.excludes then
        excludesfile = os.tmpfile()
        io.writefile(excludesfile, table.concat(table.wrap(opt.excludes), '\n'))
        table.insert(argv, "-xr@" .. excludesfile)
    end
    local includesfile
    if opt.includes then
        includesfile = os.tmpfile()
        io.writefile(includesfile, table.concat(table.wrap(opt.includes), '\n'))
        table.insert(argv, "-ir@" .. includesfile)
    end
    local compress = opt.compress
    if compress then
        if compress == "fastest" then
            table.insert(argv, "-mx1")
        elseif compress == "faster" then
            table.insert(argv, "-mx3")
        elseif compress == "better" then
            table.insert(argv, "-mx7")
        elseif compress == "best" then
            table.insert(argv, "-mx9")
        end
    end
    if opt.recurse then
        table.insert(argv, "-r")
    end
    table.insert(argv, inputdir)

    -- archive it
    os.vrunv(z7.program, argv, {curdir = opt.curdir})

    -- remove the excludes and includes file
    if excludesfile then
        os.tryrm(excludesfile)
    end
    if includesfile then
        os.tryrm(includesfile)
    end
    return true
end

-- archive archivefile using xz
function _archive_using_xz(archivefile, inputfile, extension, opt)

    -- find xz
    local xz = find_tool("xz")
    if not xz then
        return false
    end

    -- only support to compress file
    assert(not os.isdir(inputfile), "xz cannot compress directory(%s)", inputfile)

    -- init argv
    local argv = {"-z", "-k", "-c", archivefile}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    local compress = opt.compress
    if compress then
        if compress == "fastest" then
            table.insert(argv, "-1")
        elseif compress == "faster" then
            table.insert(argv, "-3")
        elseif compress == "better" then
            table.insert(argv, "-7")
        elseif compress == "best" then
            table.insert(argv, "-9")
        end
    end
    table.insert(argv, inputfile)

    -- archive it
    os.vrunv(xz.program, argv, {stdout = archivefile, curdir = opt.curdir})
    return true
end

-- archive archive file using archivers
function _archive(archivefile, inputdir, extension, archivers, opt)
    for _, archive in ipairs(archivers) do
        if archive(archivefile, inputdir, extension, opt) then
            return true
        end
    end
    return false
end

-- archive archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param inputdir      the input directory
-- @param options       the options, e.g.. {curdir = "/tmp", recurse = true, compress = "fastest|faster|default|better|best", includes = {"*/dir/*"}, excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, inputdir, opt)

    -- init inputdir
    inputdir = inputdir or os.curdir()

    -- init options
    opt = opt or {}
    if opt.recurse == nil then
        opt.recurse = true
    end

    -- init archivers
    local archivers = {
        [".zip"]        = {_archive_using_zip}
    ,   [".7z"]         = {_archive_using_7z}
    ,   [".xz"]         = {_archive_using_xz}
        --[[
    ,   [".gz"]         = {_archive_using_gzip}
    ,   [".bz2"]        = {_archive_using_bzip2}
    ,   [".tar"]        = {_archive_using_tar}
    ,   [".tar.gz"]     = {_archive_using_tar, _archive_using_gzip}
    ,   [".tar.xz"]     = {_archive_using_tar, _archive_using_xz}
    ,   [".tar.bz2"]    = {_archive_using_tar, _archive_using_bzip2}]]
    }

    -- get extension
    local extension = opt.extension or get_archive_extension(archivefile)

    -- archive it
    return _archive(archivefile, inputdir, extension, archivers[extension], opt)
end
