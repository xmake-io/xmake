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
-- @author      arthapz
-- @file        xmake.lua
--

rule("qt.qmltyperegistrar")
    add_deps("qt.env")
    set_extensions(".h", ".hpp")

    on_config(function(target)
        import("lib.detect.find_file")

        -- get qt
        local qt = assert(target:data("qt"), "Qt not found!")

        -- get qmltyperegistrar
        local search_dirs = {}
        if qt.bindir_host then table.insert(search_dirs, qt.bindir_host) end
        if qt.bindir then table.insert(search_dirs, qt.bindir) end
        if qt.libexecdir_host then table.insert(search_dirs, qt.libexecdir_host) end
        if qt.libexecdir then table.insert(search_dirs, qt.libexecdir) end
        local qmltyperegistrar = find_file(is_host("windows") and "qmltyperegistrar.exe" or "qmltyperegistrar", search_dirs)
        assert(qmltyperegistrar and os.isexec(qmltyperegistrar), "qmltyperegistrar not found!")

        -- set targetdir
        local importname = target:values("qt.qmlplugin.import_name")
        assert(importname, "QML plugin import name not set")

        local targetdir = target:targetdir()
        for _, dir in pairs(importname:split(".", { plain = true })) do
            targetdir = path.join(targetdir, dir)
        end
        os.mkdir(targetdir)
        target:set("targetdir", targetdir)

        -- add qmldir
        local qmldir = target:values("qt.qmlplugin.qmldirfile")
        if qmldir then
            target:add("installfiles", path.join(target:scriptdir(), qmldir), { prefixdir = path.join("bin", table.unpack(importname:split(".", { plain = true }))) })
        end

        -- add qmltypes
        target:add("installfiles", path.join(target:get("targetdir"), "plugin.qmltypes"), { prefixdir = path.join("bin", table.unpack(importname:split(".", { plain = true }))) })

        local genbasename = path.join(target:autogendir(), "rules", "qt", "qmltyperegistrar", target:name())
        local metatypesfile = path(genbasename .. "_metatypes.json")
        local sourcefile = path(genbasename .. "_qmltyperegistrations.cpp")
        local sourcefile_dir = path.directory(sourcefile)
        os.mkdir(sourcefile_dir)
        target:data_set("qt.qmlplugin.metatypesfile", metatypesfile)
        target:data_set("qt.qmlplugin.sourcefile", sourcefile)

        -- add moc arguments
        target:add("qt.moc.flags", "--output-json")

        -- save qmltyperegistrar
        target:data_set("qt.qmltyperegistrar", qmltyperegistrar)
        -- save qmltyperegistrar
        target:data_set("qt.qmlplugin.qmltyperegistrar", qmltyperegistrar)
     end)

     on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        -- setup qmltyperegistrar arguments
        local moc = target:data("qt.moc")
        local qmltyperegistrar = target:data("qt.qmltyperegistrar")
        local metatypesfile = target:data("qt.qmlplugin.metatypesfile")
        local sourcefile = target:data("qt.qmlplugin.sourcefile")

        local importname = target:values("qt.qmlplugin.import_name")
        local majorversion = target:values("qt.qmlplugin.majorversion") or 1
        local minorversion = target:values("qt.qmlplugin.minorversion") or 0

        local metatype_files = {}
        for _, mocedfile in ipairs(sourcebatch.sourcefiles) do
            target:add("includedirs", path.directory(mocedfile))
            local basename = path.basename(mocedfile)
            local filename_moc = "moc_" .. basename .. ".cpp"
            if mocedfile:endswith(".cpp") then
                filename_moc = basename .. ".moc"
            end
            local sourcefile_moc = target:autogenfile(path.join(path.directory(mocedfile), filename_moc))
            table.insert(metatype_files, path(sourcefile_moc .. ".json"))
        end

        -- generate a common metatypes.json file
        -- @see https://github.com/xmake-io/xmake/issues/6647
        local moc_args = {
            "--collect-json",
            "-o", metatypesfile
        }
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltyperegistrar %s", path.filename(metatypesfile))
        batchcmds:vrunv(moc, table.join(moc_args, metatype_files))

        -- gen sourcefile
        local args = {
            "--generate-qmltypes=" .. target:get("targetdir") .. "/plugin.qmltypes",
            "--import-name=" .. importname,
            "--major-version=" .. majorversion,
            "--minor-version=" .. minorversion,
            "-o", sourcefile,
            metatypesfile
        }
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.qt.qmltyperegistrar %s", path.filename(sourcefile))
        batchcmds:vrunv(qmltyperegistrar, args)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile)
        table.insert(target:objectfiles(), objectfile)

        -- compile sourcefile
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.qmltyperegistrar %s", path.filename(sourcefile))
        batchcmds:compile(sourcefile, objectfile)

        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

    after_build(function(target)
        local qmldir = target:values("qt.qmlplugin.qmldirfile")
        if qmldir then
            os.cp(path.join(target:scriptdir(), qmldir), target:targetdir())
        end
    end)
