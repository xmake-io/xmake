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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        merge_staticlib.lua
--

-- imports
import("core.base.option")
import("core.base.binutils")
import("private.tools.vstool")

-- merge *.a archive libraries using libtool
function _merge_for_ar_libtool(target, program, outputfile, libraryfiles, opt)
    os.vrunv("libtool", table.join("-static", "-o", outputfile, libraryfiles))
end

-- merge *.a archive libraries using fallback method (extract and repack)
-- Used for platforms where ar does not support -M option (e.g., Solaris)
function _merge_for_ar_fallback(target, program, outputfile, libraryfiles, opt)

    -- extract all archives to the temporary directory
    local tmpdir = os.tmpfile() .. ".dir"
    os.mkdir(tmpdir)
    for _, libraryfile in ipairs(libraryfiles) do
        binutils.extractlib(libraryfile, tmpdir)
    end

    -- collect all object files
    local objectfiles = {}
    for _, objectfile in ipairs(os.files(path.join(tmpdir, "*.o"))) do
        table.insert(objectfiles, path.filename(objectfile))
    end

    -- create new archive with all object files
    if #objectfiles > 0 then
        os.mkdir(path.directory(outputfile))
        local outputfile_abs = path.absolute(outputfile)
        -- remove output file if exists to avoid appending
        os.tryrm(outputfile_abs)
        -- create new archive with -c (create) and -r (replace/insert)
        -- use relative paths for object files since curdir = tmpdir
        os.vrunv(program, table.join("-cr", outputfile_abs, objectfiles), {curdir = tmpdir})
    end
    os.rm(tmpdir)
end

-- merge *.a archive libraries for GNU ar (using -M interactive mode)
function _merge_for_ar_gnu(target, program, outputfile, libraryfiles, opt)
    -- we can't generate directly to outputfile,
    -- because on windows/ndk, llvm-ar.exe may fail to write with no permission, even though it's a writable temp file.
    --
    -- @see https://github.com/xmake-io/xmake/issues/1973
    local archivefile = target.autogenfile and target:autogenfile((hash.uuid(outputfile):gsub("%-", ""))) .. ".a" or (os.tmpfile() .. ".a")
    os.mkdir(path.directory(archivefile))
    local tmpfile = os.tmpfile()
    local mrifile = io.open(tmpfile, "w")
    mrifile:print("create %s", archivefile)
    for _, libraryfile in ipairs(libraryfiles) do
        mrifile:print("addlib %s", libraryfile)
    end
    mrifile:print("save")
    mrifile:print("end")
    mrifile:close()
    os.vrunv(program, {"-M"}, {stdin = tmpfile})
    os.cp(archivefile, outputfile)
    os.rm(tmpfile)
    os.rm(archivefile)
end

-- merge *.a archive libraries for ar
function _merge_for_ar(target, program, outputfile, libraryfiles, opt)
    opt = opt or {}
    if target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
        _merge_for_ar_libtool(target, program, outputfile, libraryfiles, opt)
    elseif target:is_plat("solaris") then
        _merge_for_ar_fallback(target, program, outputfile, libraryfiles, opt)
    else
        _merge_for_ar_gnu(target, program, outputfile, libraryfiles, opt)
    end
end

-- merge *.a archive libraries for msvc/lib.exe
function _merge_for_msvclib(target, program, outputfile, libraryfiles, opt)
    opt = opt or {}
    vstool.runv(program, table.join("-nologo", "-out:" .. outputfile, libraryfiles), {envs = opt.runenvs})
end

-- merge *.a archive libraries, @note target may be package.
function main(target, outputfile, libraryfiles)
    local program, toolname = target:tool("ar")
    if program and toolname then
        if toolname:find("ar") then
            _merge_for_ar(target, program, outputfile, libraryfiles)
        elseif toolname == "link" and target:is_plat("windows") then
            local msvc
            for _, toolchain_inst in ipairs(target:toolchains()) do
                if toolchain_inst:name() == "msvc" then
                    msvc = toolchain_inst
                    break
                end
            end
            _merge_for_msvclib(target, (program:gsub("link%.exe", "lib.exe")), outputfile, libraryfiles, {runenvs = msvc and msvc:runenvs()})
        else
            raise("cannot merge (%s): unknown ar tool %s!", table.concat(libraryfiles, ", "), toolname)
        end
    else
        raise("cannot merge (%s): ar not found!", table.concat(libraryfiles, ", "))
    end
end

