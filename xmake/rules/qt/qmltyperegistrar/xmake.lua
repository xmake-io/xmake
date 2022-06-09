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
-- @author      arthapz
-- @file        xmake.lua
--

rule("qt.qmltyperegistrar")
    add_deps("qt.env")
    set_extensions(".h", ".hpp")

    on_load(function(target)
        -- get qt
        local qt = assert(target:data("qt"), "qt not found!")

        -- get qmltyperegistrar
        local qmltyperegistrar = path.join(qt.bindir, is_host("windows") and "qmltyperegistrar.exe" or "qmltyperegistrar")
        if not os.isexec(qmltyperegistrar) and qt.libexecdir then
            qmltyperegistrar = path.join(qt.libexecdir, is_host("windows") and "qmltyperegistrar.exe" or "qmltyperegistrar")
        end
        if not os.isexec(qmltyperegistrar) and qt.libexecdir_host then
            qmltyperegistrar = path.join(qt.libexecdir_host, is_host("windows") and "qmltyperegistrar.exe" or "qmltyperegistrar")
        end
        assert(qmltyperegistrar and os.isexec(qmltyperegistrar), "qmltyperegistrar not found!")

        -- set targetdir
        local importname = target:values("qml.plugin.importname")
        local targetdir = path.join(target:targetdir(), "imports")
        for _, dir in pairs(importname:split(".", { plain = true })) do
            targetdir = path.join(targetdir, dir)
        end

        os.mkdir(targetdir)
        target:set("targetdir", targetdir)

        -- add qmldir
        local qmldir = target:values("qml.plugin.qmldir")

        if qmldir then
            target:add("installfiles", qmldir)
        end

        local sourcefile = path.join(target:autogendir(), "rules", "qt", "qmltyperegistrar", target:name() .. "_qmltyperegistrations.cpp")
        local sourcefile_dir = path.directory(sourcefile)
        os.mkdir(sourcefile_dir)
        target:data_set("qml.plugin.sourcefile", sourcefile)

        -- add moc arguments
        target:add("qt.moc.flags", "--output-json")

        -- save qmltyperegistrar
        target:data_set("qt.qmltyperegistrar", qmltyperegistrar)
        -- save qmltyperegistrar
        target:data_set("qml.plugin.qmltyperegistrar", qmltyperegistrar)
     end)

     on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        assert(target:values("qml.plugin.importname"), "QML plugin import name not set")

        -- setup qmltyperegistrar arguments
        local qmltyperegistrar = target:data("qt.qmltyperegistrar")
        local sourcefile = target:data("qml.plugin.sourcefile")

        local importname = target:values("qml.plugin.importname")
        local majorversion = target:values("qml.plugin.majorversion") or 1
        local minorversion = target:values("qml.plugin.minorversion") or 0

        local metatypefiles = {}
        for _, mocedfile in ipairs(sourcebatch.sourcefiles) do
            target:add("includedirs", path.directory(mocedfile))
            local basename = path.basename(mocedfile)
            local filename_moc = "moc_" .. basename .. ".cpp"
            if mocedfile:endswith(".cpp") then
                filename_moc = basename .. ".moc"
            end

            local sourcefile_moc = target:autogenfile(path.join(path.directory(mocedfile), filename_moc))

            table.insert(metatypefiles, path(sourcefile_moc .. ".json"))
        end

        local args = {
            "--generate-qmltypes=" .. target:get("targetdir") .. "/plugin.qmltypes", 
            "--import-name=" .. importname,
            "--major-version=" .. majorversion,
            "--minor-version=" .. minorversion,
            "-o", path(sourcefile)
        }

        -- gen sourcefile
        batchcmds:show_progress(opt.progress, "${color.build.object}generate.qt.qmltyperegistrar %s", path.filename(sourcefile))
        qmltype_source = os.vrunv(qmltyperegistrar, table.join(args, metatypefiles))

        -- add objectfile
        local objectfile = target:objectfile(sourcefile)
        table.insert(target:objectfiles(), objectfile)

        -- compile sourcefile
        batchcmds:show_progress(opt.progress, "${color.build.object}compile.qt.qmltyperegistrar %s", path.filename(sourcefile))

        batchcmds:compile(sourcefile, objectfile)

        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)

    after_build(function(target)
        local qmldir = target:values("qml.plugin.qmldir")

        if qmldir then
            os.cp(qmldir, target:targetdir())
        end
    end)