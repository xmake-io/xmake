--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: environment
rule("qt.env")

    -- on load
    on_load(function (target)
        import("detect.sdks.find_qt")
        if not target:data("qt") then
            target:data_set("qt", assert(find_qt(nil, {verbose = true}), "Qt SDK not found!"))
        end
    end)

    -- before run
    before_run(function (target)
        local qt = target:data("qt")
        if qt and (is_plat("windows") or (is_plat("mingw") and is_host("windows"))) then
            os.addenv("PATH", qt.bindir)
        end
    end)

    -- clean files
    after_clean(function (target)
        for _, file in ipairs(target:data("qt.cleanfiles")) do
            os.rm(file)
        end
        target:data_set("qt.cleanfiles", nil)
    end)

-- define rule: *.ui
rule("qt.ui")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".ui")

    -- on load
    on_load(function (target)
        
        -- get uic
        local uic = path.join(target:data("qt").bindir, is_host("windows") and "uic.exe" or "uic")
        assert(uic and os.isexec(uic), "uic not found!")
        
        -- save uic
        target:data_set("qt.uic", uic)
    end)

    -- before build file
    before_build_file(function (target, sourcefile_ui, opt)

        -- imports
        import("core.base.option")
        import("core.project.config")
        import("core.project.depend")

        -- get uic
        local uic = target:data("qt.uic")

        -- get c++ header file for ui
        local headerfile_ui = path.join(config.buildir(), ".qt", "ui", target:name(), "ui_" .. path.basename(sourcefile_ui) .. ".h")
        local headerfile_dir = path.directory(headerfile_ui)

        -- add includedirs
        target:add("includedirs", path.absolute(headerfile_dir, os.projectdir()))

        -- add clean files
        target:data_add("qt.cleanfiles", headerfile_ui)

        -- need build this object?
        local dependfile = target:dependfile(headerfile_ui)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile_ui)}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.qt.ui %s", opt.progress, sourcefile_ui)
        else
            cprint("${green}[%02d%%]:${clear} compiling.qt.ui %s", opt.progress, sourcefile_ui)
        end

        -- ensure ui header file directory
        if not os.isdir(headerfile_dir) then
            os.mkdir(headerfile_dir)
        end

        -- compile ui 
        os.vrunv(uic, {sourcefile_ui, "-o", headerfile_ui})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile_ui}
        depend.save(dependinfo, dependfile)
    end)

-- define rule: moc
rule("qt.moc")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".h")

    -- on load
    on_load(function (target)
        
        -- get moc
        local moc = path.join(target:data("qt").bindir, is_host("windows") and "moc.exe" or "moc")
        assert(moc and os.isexec(moc), "moc not found!")
        
        -- save moc
        target:data_set("qt.moc", moc)
    end)

    -- on build file
    on_build_file(function (target, headerfile_moc, opt)

        -- imports
        import("moc")
        import("core.base.option")
        import("core.project.config")
        import("core.tool.compiler")
        import("core.project.depend")

        -- get c++ source file for moc
        local sourcefile_moc = path.join(config.buildir(), ".qt", "moc", target:name(), "moc_" .. path.basename(headerfile_moc) .. ".cpp")

        -- get object file
        local objectfile = target:objectfile(sourcefile_moc)

        -- load compiler 
        local compinst = compiler.load("cxx", {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_moc})

        -- add objectfile
        table.insert(target:objectfiles(), objectfile)

        -- add clean files
        target:data_add("qt.cleanfiles", {sourcefile_moc, objectfile})

        -- load dependent info 
        local dependfile = target:dependfile(objectfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        local depvalues = {compinst:program(), compflags}
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.qt.moc %s", opt.progress, headerfile_moc)
        else
            cprint("${green}[%02d%%]:${clear} compiling.qt.moc %s", opt.progress, headerfile_moc)
        end

        -- generate c++ source file for moc
        moc.generate(target, headerfile_moc, sourcefile_moc)

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_moc, objectfile, {compflags = compflags}))
        end

        -- compile c++ source file for moc
        dependinfo.files = {}
        compinst:compile(sourcefile_moc, objectfile, {dependinfo = dependinfo, compflags = compflags})

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, headerfile_moc)
        depend.save(dependinfo, dependfile)
    end)

-- define rule: *.qrc
rule("qt.qrc")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".qrc")

    -- on load
    on_load(function (target)
        
        -- get rcc
        local rcc = path.join(target:data("qt").bindir, is_host("windows") and "rcc.exe" or "rcc")
        assert(rcc and os.isexec(rcc), "rcc not found!")
        
        -- save rcc
        target:data_set("qt.rcc", rcc)
    end)

    -- on build file
    on_build_file(function (target, sourcefile_qrc, opt)

        -- imports
        import("core.base.option")
        import("core.project.config")
        import("core.project.depend")
        import("core.tool.compiler")

        -- get rcc
        local rcc = target:data("qt.rcc")

        -- get c++ source file for qrc
        local sourcefile_cpp = path.join(config.buildir(), ".qt", "qrc", target:name(), path.basename(sourcefile_qrc) .. ".cpp")
        local sourcefile_dir = path.directory(sourcefile_cpp)

        -- get object file
        local objectfile = target:objectfile(sourcefile_cpp)

        -- load compiler 
        local compinst = compiler.load("cxx", {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_cpp})

        -- add objectfile
        table.insert(target:objectfiles(), objectfile)

        -- add clean files
        target:data_add("qt.cleanfiles", {sourcefile_cpp, objectfile})

        -- load dependent info 
        local dependfile = target:dependfile(objectfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        local depvalues = {compinst:program(), compflags}
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.qt.qrc %s", opt.progress, sourcefile_qrc)
        else
            cprint("${green}[%02d%%]:${clear} compiling.qt.qrc %s", opt.progress, sourcefile_qrc)
        end

        -- ensure the source file directory
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- compile qrc 
        os.vrunv(rcc, {"-name", "qml", sourcefile_qrc, "-o", sourcefile_cpp})

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_cpp, objectfile, {compflags = compflags}))
        end

        -- compile c++ source file for qrc
        dependinfo.files = {}
        compinst:compile(sourcefile_cpp, objectfile, {dependinfo = dependinfo, compflags = compflags})

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile_qrc)
        depend.save(dependinfo, dependfile)
    end)

-- define rule: qt static library
rule("qt.static")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "static", frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "shared", frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", frameworks = {"QtCore"}})
    end)

-- define rule: qt application
rule("qt.application")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- on load
    on_load(function (target)

        -- load common flags to target
        import("load")(target, {kind = "binary", frameworks = {"QtGui", "QtQml", "QtNetwork", "QtCore"}})

        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-Wl,-subsystem:windows", "-Wl,-entry:mainCRTStartup", {force = true})
        end
    end)

