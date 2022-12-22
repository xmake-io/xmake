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
import("detect.tools.find_bzip2")
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
    if is_host("windows") then
        -- force "x:\\xx" as local file
        local force_local = _g.force_local
        if force_local == nil then
            force_local = try {function ()
                local result = os.iorunv(program, {"--help"})
                if result and result:find("--force-local", 1, true) then
                    return true
                end
            end}
            _g.force_local = force_local or false
        end
        if force_local then
            table.insert(argv, "--force-local")
        end
    end
    table.insert(argv, "-xf")
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
        os.vrunv(program, argv, {curdir = outputdir})
    else
        os.vrunv(program, argv)
    end
    return true
end

-- extract archivefile using 7z
function _extract_using_7z(archivefile, outputdir, extension, opt)

    -- find 7z
    local program = find_7z()
    if not program then
        return false
    end

    -- p7zip cannot extract other archive format on msys/cygwin
    -- https://github.com/xmake-io/xmake/issues/1575#issuecomment-898205462
    if is_subhost("msys", "cygwin") and extension ~= ".7z" and program:startswith("sh ") then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") or extension == ".tgz" then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- on msys2/cygwin? we need translate input path to cygwin-like path
    if is_subhost("msys", "cygwin") and program:gsub("\\", "/"):find("/usr/bin") then
        archivefile = path.cygwin_path(archivefile)
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
        io.writefile(excludesfile, table.concat(table.wrap(opt.excludes), '\n'))
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
        os.tryrm(path.join(outputdir, "PaxHeaders*"))
        os.tryrm(path.join(outputdir, "@PaxHeader"))
    end

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end
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

    -- extract it
    os.vrunv(program, argv, {curdir = outputdir})

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end
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

    -- extract it
    os.vrunv(program, argv, {curdir = outputdir})

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end
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
    local argv = {"-o"} -- overwrite existing files without prompting
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
    return true
end

-- extract archivefile using bzip2
function _extract_using_bzip2(archivefile, outputdir, extension, opt)

    -- find bzip2
    local program = find_bzip2()
    if not program then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- on msys2/cygwin? we need translate input path to cygwin-like path
    if is_subhost("msys", "cygwin") and program:gsub("\\", "/"):find("/usr/bin") then
        archivefile = path.cygwin_path(archivefile)
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

    -- extract it
    os.vrunv(program, argv, {curdir = outputdir})

    -- continue to extract *.tar file
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end
    return true
end

-- extract archive file using extractors
function _extract(archivefile, outputdir, extension, extractors, opt)
    for _, extract in ipairs(extractors) do
        local ok = try {function () return extract(archivefile, outputdir, extension, opt) end}
        if ok then
            return true
        end
    end
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
    local extractors
    if is_subhost("windows") then
        -- we use 7z first, becase xmake package has builtin 7z program on windows
        -- tar/windows can not extract .bz2 ...
        extractors =
        {
            [".zip"]        = {_extract_using_7z, _extract_using_unzip, _extract_using_tar}
        ,   [".7z"]         = {_extract_using_7z}
        ,   [".gz"]         = {_extract_using_7z, _extract_using_gzip, _extract_using_tar}
        ,   [".xz"]         = {_extract_using_7z, _extract_using_xz, _extract_using_tar}
        ,   [".tgz"]        = {_extract_using_7z, _extract_using_tar}
        ,   [".bz2"]        = {_extract_using_7z, _extract_using_bzip2}
        ,   [".tar"]        = {_extract_using_7z, _extract_using_tar}
        ,   [".tar.gz"]     = {_extract_using_7z, _extract_using_gzip}
        ,   [".tar.xz"]     = {_extract_using_7z, _extract_using_xz}
        ,   [".tar.bz2"]    = {_extract_using_7z, _extract_using_bzip2}
        ,   [".tar.lz"]     = {_extract_using_7z}
        }
    else
        extractors =
        {
            -- tar supports .zip on macOS but does not on Linux
            [".zip"]        = is_host("macosx") and {_extract_using_unzip, _extract_using_tar, _extract_using_7z} or {_extract_using_unzip, _extract_using_7z}
        ,   [".7z"]         = {_extract_using_7z}
        ,   [".gz"]         = {_extract_using_gzip, _extract_using_tar, _extract_using_7z}
        ,   [".xz"]         = {_extract_using_xz, _extract_using_tar, _extract_using_7z}
        ,   [".tgz"]        = {_extract_using_tar, _extract_using_7z}
        ,   [".bz2"]        = {_extract_using_bzip2, _extract_using_tar, _extract_using_7z}
        ,   [".tar"]        = {_extract_using_tar, _extract_using_7z}
        ,   [".tar.gz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_gzip}
        ,   [".tar.xz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_xz}
        ,   [".tar.bz2"]    = {_extract_using_tar, _extract_using_7z, _extract_using_bzip2}
        ,   [".tar.lz"]     = {_extract_using_tar, _extract_using_7z}
        }
    end

    -- get extension
    local extension = opt.extension or get_archive_extension(archivefile)

    -- extract it
    return _extract(archivefile, outputdir, extension, extractors[extension], opt)
end
