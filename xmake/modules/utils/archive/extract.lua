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
import("lib.detect.find_tool")
import("extract_xmz")
import("extension", {alias = "get_archive_extension"})

-- extract archivefile using xmake decompress module
function _extract_using_xmz(archivefile, outputdir, extension, opt)
    extract_xmz(archivefile, outputdir, opt)
    return true
end

-- extract archivefile using tar
function _extract_using_tar(archivefile, outputdir, extension, opt)

    -- the tar on windows can only extract "*.tar", "*.tar.gz"
    -- the tar on msys2 can extract more, like "*.tar.bz2", ..
    if os.host() == "windows" and (extension ~= ".tar" and extension ~= ".tar.gz") then
        return false
    end

    -- find tar
    local tar = find_tool("tar")
    if not tar then
        return false
    end
    local program = tar.program

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
    table.insert(argv, path.absolute(archivefile))

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
    local z7 = find_tool("7z")
    if not z7 then
        return false
    end
    local program = z7.program

    -- p7zip cannot extract other archive format on msys/cygwin, but it can extract .tgz
    -- https://github.com/xmake-io/xmake/issues/1575#issuecomment-898205462
    if is_subhost("msys", "cygwin") and program:startswith("sh ") and
        extension ~= ".7z" and extension ~= ".tgz" then
        return false
    end

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") or extension == ".tgz" then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- on msys2/cygwin? we need to translate input path to cygwin-like path
    if is_subhost("msys", "cygwin") and program:gsub("\\", "/"):find("/usr/bin") then
        archivefile = path.cygwin_path(archivefile)
    end

    -- init argv
    local argv = {"x", "-y", archivefile}

    -- disable to store symlinks on windows
    if is_host("windows") then
        table.insert(argv, "-snl-")
    end

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
        -- https://github.com/xmake-io/xmake-repo/pull/2673
        os.tryrm(path.join(outputdir, "*.paxheader"))
    end

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract archivefile using gzip
function _extract_using_gzip(archivefile, outputdir, extension, opt)

    -- find gzip
    local gzip = find_tool("gzip")
    if not gzip then
        return false
    end
    local program = gzip.program

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

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract archivefile using xz
function _extract_using_xz(archivefile, outputdir, extension, opt)

    -- find xz
    local xz = find_tool("xz")
    if not xz then
        return false
    end
    local program = xz.program

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

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract archivefile using zstd
function _extract_using_zstd(archivefile, outputdir, extension, opt)

    -- find zstd
    local zstd = find_tool("zstd")
    if not zstd then
        return false
    end
    local program = zstd.program

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- init temporary archivefile
    local tmpfile = path.join(outputdir, path.filename(archivefile))

    -- init argv
    local argv = {"-d"}
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

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract archivefile using unzip
function _extract_using_unzip(archivefile, outputdir, extension, opt)

    -- find unzip
    local unzip = find_tool("unzip")
    if not unzip then
        return false
    end
    local program = unzip.program

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

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract archivefile using powershell
-- powershell -ExecutionPolicy Bypass -File "D:\scripts\unzip.ps1" "archivefile" "outputdir"
function _extract_using_powershell(archivefile, outputdir, extension, opt)

    -- find powershell
    local powershell = find_tool("pwsh") or find_tool("powershell")
    if not powershell then
        return false
    end

    -- get the script file
    local scriptfile = path.join(os.programdir(), "scripts", "unzip.ps1")

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- extract it
    local argv = {"-ExecutionPolicy", "Bypass", "-File", scriptfile, archivefile, outputdir}
    os.vrunv(powershell.program, argv)

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end


-- extract archivefile using bzip2
function _extract_using_bzip2(archivefile, outputdir, extension, opt)

    -- find bzip2
    local bzip2 = find_tool("bzip2")
    if not bzip2 then
        return false
    end
    local program = bzip2.program

    -- extract to *.tar file first
    local outputdir_old = nil
    if extension:startswith(".tar.") then
        outputdir_old = outputdir
        outputdir = os.tmpfile({ramdisk = false}) .. ".tar"
    end

    -- on msys2/cygwin? we need to translate input path to cygwin-like path
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

    _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    return true
end

-- extract *.tar after decompress
function _extract_uncompressed_tar(outputdir_old, outputdir, opt)
    if outputdir_old then
        local tarfile = find_file("**.tar", outputdir)
        if tarfile and os.isfile(tarfile) then
            return _extract(tarfile, outputdir_old, ".tar", {_extract_using_7z, _extract_using_tar}, opt)
        end
    end
end

-- extract archive file using extractors
function _extract(archivefile, outputdir, extension, extractors, opt)
    local errors
    for _, extract in ipairs(extractors) do
        local ok = try {
            function ()
                return extract(archivefile, outputdir, extension, opt)
            end,
            catch {
                function (errs)
                    if errs then
                        errors = tostring(errs)
                    end
                end
            }
        }
        if ok then
            return true
        end
    end
    raise("cannot extract %s, %s!", path.filename(archivefile), errors or "no extractor(like unzip, ...) found")
end

-- extract file
--
-- @param archivefile   the archive file. e.g. *.tar.gz, *.zip, *.7z, *.tar.bz2, ..
-- @param outputdir     the output directory
-- @param options       the options, e.g.. {excludes = {"*/dir/*", "dir/*"}}
--
function main(archivefile, outputdir, opt)
    opt = opt or {}
    outputdir = outputdir or os.curdir()

    -- init extractors
    local extractors
    if is_subhost("windows") then
        -- we use 7z first, becase xmake package has builtin 7z program on windows
        -- tar/windows can not extract .bz2 ...
        -- 7z doesn't support zstd by default
        extractors =
        {
            [".zip"]        = {_extract_using_7z, _extract_using_unzip, _extract_using_tar, _extract_using_powershell}
        ,   [".7z"]         = {_extract_using_7z}
        ,   [".gz"]         = {_extract_using_7z, _extract_using_gzip, _extract_using_tar}
        ,   [".xz"]         = {_extract_using_7z, _extract_using_xz, _extract_using_tar}
        ,   [".zst"]        = {_extract_using_zstd, _extract_using_tar}
        ,   [".tgz"]        = {_extract_using_7z, _extract_using_tar}
        ,   [".bz2"]        = {_extract_using_7z, _extract_using_bzip2}
        ,   [".tar"]        = {_extract_using_7z, _extract_using_tar}
        -- @see https://github.com/xmake-io/xmake/issues/5538
        ,   [".tar.gz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_gzip}
        ,   [".tar.xz"]     = {_extract_using_7z, _extract_using_xz}
        ,   [".tar.zst"]    = {_extract_using_zstd}
        ,   [".tar.bz2"]    = {_extract_using_7z, _extract_using_bzip2}
        ,   [".tar.lz"]     = {_extract_using_7z}
        ,   [".tar.Z"]      = {_extract_using_7z}
        ,   [".xmz"]        = {_extract_using_xmz}
        }
    else
        extractors =
        {
            -- tar supports .zip on macOS but does not on Linux
            [".zip"]        = is_host("macosx") and {_extract_using_unzip, _extract_using_tar, _extract_using_7z} or {_extract_using_unzip, _extract_using_7z}
        ,   [".7z"]         = {_extract_using_7z}
        ,   [".gz"]         = {_extract_using_gzip, _extract_using_tar, _extract_using_7z}
        ,   [".xz"]         = {_extract_using_xz, _extract_using_tar, _extract_using_7z}
        ,   [".zst"]        = {_extract_using_zstd, _extract_using_tar}
        ,   [".tgz"]        = {_extract_using_tar, _extract_using_7z}
        ,   [".bz2"]        = {_extract_using_bzip2, _extract_using_tar, _extract_using_7z}
        ,   [".tar"]        = {_extract_using_tar, _extract_using_7z}
        ,   [".tar.gz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_gzip}
        ,   [".tar.xz"]     = {_extract_using_tar, _extract_using_7z, _extract_using_xz}
        ,   [".tar.zst"]     = {_extract_using_tar, _extract_using_zstd}
        ,   [".tar.bz2"]    = {_extract_using_tar, _extract_using_7z, _extract_using_bzip2}
        ,   [".tar.lz"]     = {_extract_using_tar, _extract_using_7z}
        ,   [".tar.Z"]      = {_extract_using_tar, _extract_using_7z}
        ,   [".xmz"]        = {_extract_using_xmz}
        }
    end

    -- get extension
    local extension = opt.extension or get_archive_extension(archivefile)

    -- extract it
    return _extract(archivefile, outputdir, extension, extractors[extension], opt)
end
