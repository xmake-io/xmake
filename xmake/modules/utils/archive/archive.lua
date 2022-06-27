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
function _archive_using_zip(archivefile, inputfiles, extension, opt)

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
    local inputlistfile = os.tmpfile()
    if type(inputfiles) == "table" then
        local file = io.open(inputlistfile, "w")
        for _, inputfile in ipairs(inputfiles) do
            file:print(inputfile)
        end
        file:close()
        table.insert(argv, "-@")
    else
        table.insert(argv, inputfiles)
    end

    -- archive it
    os.vrunv(zip.program, argv, {curdir = opt.curdir, stdin = inputlistfile})
    if inputlistfile then
        os.tryrm(inputlistfile)
    end
    return true
end

-- archive archivefile using 7z
function _archive_using_7z(archivefile, inputfiles, extension, opt)

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
    local inputlistfile = os.tmpfile()
    if type(inputfiles) == "table" then
        local file = io.open(inputlistfile, "w")
        for _, inputfile in ipairs(inputfiles) do
            file:print(inputfile)
        end
        file:close()
        table.insert(argv, "-i@" .. inputlistfile)
    else
        table.insert(argv, inputfiles)
    end

    -- archive it
    os.vrunv(z7.program, argv, {curdir = opt.curdir})

    -- remove the excludes files
    if excludesfile then
        os.tryrm(excludesfile)
    end
    if inputlistfile then
        os.tryrm(inputlistfile)
    end
    return true
end

-- archive archivefile using xz
function _archive_using_xz(archivefile, inputfiles, extension, opt)

    -- find xz
    local xz = find_tool("xz")
    if not xz then
        return false
    end

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
    if type(inputfiles) == "table" then
        for _, inputfile in ipairs(inputfiles) do
            table.insert(argv, inputfile)
        end
    else
        table.insert(argv, inputfiles)
    end

    -- archive it
    os.vrunv(xz.program, argv, {stdout = archivefile, curdir = opt.curdir})
    return true
end

-- archive archivefile using gzip
function _archive_using_gzip(archivefile, inputfiles, extension, opt)

    -- find gzip
    local gzip = find_tool("gzip")
    if not gzip then
        return false
    end

    -- init argv
    local argv = {"-k", "-c", archivefile}
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
    if opt.recurse then
        table.insert(argv, "-r")
    end
    if type(inputfiles) == "table" then
        for _, inputfile in ipairs(inputfiles) do
            table.insert(argv, inputfile)
        end
    else
        table.insert(argv, inputfiles)
    end

    -- archive it
    os.vrunv(gzip.program, argv, {stdout = archivefile, curdir = opt.curdir})
    return true
end

-- archive archivefile using tar
function _archive_using_tar(archivefile, inputfiles, extension, opt)

    -- find tar
    local tar = find_tool("tar")
    if not tar then
        return false
    end

    -- with compress? e.g. .tar.xz
    local compress = false
    local archivefile_tar
    if extension ~= ".tar" then
        if is_host("windows") then
            return false
        else
            compress = true
            archivefile_tar = path.join(path.directory(archivefile), path.basename(archivefile))
        end
    end

    -- init argv
    local argv = {}
    if compress then
        table.insert(argv, "-a")
    end
    if option.get("verbose") then
        table.insert(argv, "-cvf")
    else
        table.insert(argv, "-cf")
    end
    table.insert(argv, archivefile_tar and archivefile_tar or archivefile)
    if opt.excludes then
        for _, exclude in ipairs(opt.excludes) do
            table.insert(argv, "--exclude=")
            table.insert(argv, exclude)
        end
    end
    if not opt.recurse then
        table.insert(argv, "-n")
    end
    local inputlistfile = os.tmpfile()
    if type(inputfiles) == "table" then
        local file = io.open(inputlistfile, "w")
        for _, inputfile in ipairs(inputfiles) do
            file:print(inputfile)
        end
        file:close()
        table.insert(argv, "-T")
        table.insert(argv, inputlistfile)
    else
        table.insert(argv, inputfiles)
    end

    -- archive it
    os.vrunv(tar.program, argv, {curdir = opt.curdir})
    if inputlistfile then
        os.tryrm(inputlistfile)
    end
    if archivefile_tar and os.isfile(archivefile_tar) then
        _archive_tarfile(archivefile, archivefile_tar, opt)
        os.rm(archivefile_tar)
    end
    return true
end

-- archive archive file using archivers
function _archive(archivefile, inputfiles, extension, archivers, opt)
    for _, archive in ipairs(archivers) do
        if archive(archivefile, inputfiles, extension, opt) then
            return true
        end
    end
    return false
end

-- only archive tar file
function _archive_tarfile(archivefile, tarfile, opt)
    local archivers = {
        [".xz"]         = {_archive_using_xz}
    ,   [".gz"]         = {_archive_using_gzip}
    }
    local extension = opt.extension or path.extension(archivefile)
    return _archive(archivefile, tarfile, extension, archivers[extension], opt)
end

-- archive archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param inputfiles    the input file or directory or list
-- @param options       the options, e.g.. {curdir = "/tmp", recurse = true, compress = "fastest|faster|default|better|best", excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, inputfiles, opt)

    -- init inputfiles
    inputfiles = inputfiles or os.curdir()

    -- init options
    opt = opt or {}
    if opt.recurse == nil then
        opt.recurse = true
    end

    -- init archivers
    local archivers = {
        [".zip"]        = {_archive_using_zip, _archive_using_7z}
    ,   [".7z"]         = {_archive_using_7z}
    ,   [".xz"]         = {_archive_using_xz}
    ,   [".gz"]         = {_archive_using_gzip}
    ,   [".tar"]        = {_archive_using_tar}
    ,   [".tar.gz"]     = {_archive_using_tar, _archive_using_gzip}
    ,   [".tar.xz"]     = {_archive_using_tar, _archive_using_xz}
    }

    -- get extension
    local extension = opt.extension or get_archive_extension(archivefile)

    -- archive it
    return _archive(archivefile, inputfiles, extension, archivers[extension], opt)
end
