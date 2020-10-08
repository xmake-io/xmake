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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        extract.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")
import("detect.tools.find_xz")
import("detect.tools.find_7z")
import("detect.tools.find_tar")
import("detect.tools.find_gzip")
import("detect.tools.find_unzip")
import("extension", {alias = "get_archive_extension"})

-- extract archivefile using tar
function _extract_using_tar(archivefile, outputdir, extension, opt)

    -- the tar of windows can only extract "*.tar"
    if os.host() == "windows" and extension ~= ".tar" then
        return false
    end

    -- find tar
    local program = find_tar()
    if not program then
        return false
    end

    -- init argv
    local argv = {}
    if is_subhost("windows") then
        -- force "x:\\xx" as local file
        table.insert(argv, "--force-local")
    end
    table.insert(argv, option.get("verbose") and "-xvf" or "-xf")
    table.insert(argv, archivefile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputdir
    if not is_host("windows") then
        table.insert(argv, "-C")
        table.insert(argv, outputdir)
    end

    -- excludes files
    if opt.excludes then
        table.insert(argv, "--exclude")
        for _, exclude in ipairs(opt.excludes) do
            table.insert(argv, exclude)
        end
    end

    -- extract it
    if is_host("windows") then
        local oldir = os.cd(outputdir)
        os.vrunv(program, argv)
        os.cd(oldir)
    else
        os.vrunv(program, argv)
    end

    -- ok
    return true
end

-- extract archivefile using 7z
function _extract_using_7z(archivefile, outputdir, extension, opt)

    -- find 7z
    local program = find_7z()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- init argv
    local argv = {"x", "-y", archivefile}

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputdir
    table.insert(argv, "-o" .. outputdir)

    -- excludes files
    local excludesfile = nil
    if opt.excludes and not outputdir_old then
        excludesfile = os.tmpfile()
        io.writefile(excludesfile, table.concat(opt.excludes, '\n'))
        table.insert(argv, "-xr@" .. excludesfile)
    end

    -- extract it
    os.vrunv(program, argv)

    -- remove the excludes file
    if excludesfile then
        os.tryrm(excludesfile)
    end

    -- remove unused pax_global_header file after extracting .tar file
    if extension == ".tar" then
        os.tryrm(path.join(outputdir, "pax_global_header"))
        os.tryrm(path.join(outputdir, "PaxHeaders.*"))
    end

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end

    -- ok
    return true
end

-- extract archivefile using gzip
function _extract_using_gzip(archivefile, outputdir, extension, opt)

    -- find gzip
    local program = find_gzip()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- init temporary archivefile
    local tmpfile = path.join(outputdir, path.filename(archivefile))

    -- init argv
    local argv = {"-d", "-f"}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, tmpfile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- copy archivefile to outputdir first
    if path.absolute(archivefile) ~= path.absolute(tmpfile) then
        os.cp(archivefile, tmpfile)
    end

    -- enter outputdir
    local oldir = os.cd(outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- leave outputdir
    os.cd(oldir)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end

    -- ok
    return true
end

-- extract archivefile using xz
function _extract_using_xz(archivefile, outputdir, extension, opt)

    -- find xz
    local program = find_xz()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- init temporary archivefile
    local tmpfile = path.join(outputdir, path.filename(archivefile))

    -- init argv
    local argv = {"-d", "-f"}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, tmpfile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- copy archivefile to outputdir first
    if path.absolute(archivefile) ~= path.absolute(tmpfile) then
        os.cp(archivefile, tmpfile)
    end

    -- enter outputdir
    local oldir = os.cd(outputdir)

    -- extract it
    os.vrunv(program, argv)

    -- leave outputdir
    os.cd(oldir)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end

    -- ok
    return true
end

-- extract archivefile using unzip
function _extract_using_unzip(archivefile, outputdir, extension, opt)

    -- find unzip
    local program = find_unzip()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- init argv
    local argv = {}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, archivefile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- extract to outputdir
    table.insert(argv, "-d")
    table.insert(argv, outputdir)

    -- excludes files
    if opt.excludes and not outputdir_old then
        table.insert(argv, "-x")
        for _, exclude in ipairs(opt.excludes) do
            table.insert(argv, exclude)
        end
    end

    -- extract it
    os.vrunv(program, argv)

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_tar, _extract_using_7z}, opt)
        end
    end

    -- ok
    return true
end

-- extract archive file using extractors
function _extract(archivefile, outputdir, extension, extractors, opt)

    -- extract it
    for _, extract in ipairs(extractors) do
        if extract(archivefile, outputdir, extension, opt) then
            return true
        end
    end

    -- failed
    return false
end

-- extract archive file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param outputdir     the output directory
-- @param options       the options, e.g.. {excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, outputdir, opt)

    -- init outputdir
    outputdir = outputdir or os.curdir()

    -- init options
    opt = opt or {}

    -- init extractors
    local extractors =
    {
        [".zip"]        = {_extract_using_unzip, _extract_using_tar, _extract_using_7z}
    ,   [".7z"]         = {_extract_using_7z}
    ,   [".gz"]         = {_extract_using_gzip, _extract_using_tar, _extract_using_7z}
    ,   [".xz"]         = {_extract_using_xz, _extract_using_tar, _extract_using_7z}
    ,   [".tgz"]        = {_extract_using_tar, _extract_using_7z}
    ,   [".bz2"]        = {_extract_using_tar, _extract_using_7z}
    ,   [".tar"]        = {_extract_using_tar, _extract_using_7z}
    ,   [".tar.gz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_gzip}
    ,   [".tar.xz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_xz}
    ,   [".tar.bz2"]    = {_extract_using_tar, _extract_using_7z}
    }

    -- get extension
    local extension = opt.extension or get_archive_extension(archivefile)

    -- extract it
    return _extract(archivefile, outputdir, extension, extractors[extension], opt)
end
