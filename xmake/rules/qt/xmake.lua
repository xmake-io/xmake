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

-- define rule: qt static library
rule("qt.static")

    -- add rule: qt environment
    add_deps("qt.env")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "static", frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")

    -- add rule: qt environment
    add_deps("qt.env")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "shared", frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")

    -- add rule: qt environment
    add_deps("qt.env")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", frameworks = {"QtCore"}})
    end)

-- define rule: qt widget application
rule("qt.widgetapp")

    -- add rule: qt environment
    add_deps("qt.env")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", frameworks = {"QtGui", "QtCore"}})
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
    on_build_file(function (target, sourcefile_qrc)

        -- imports
        import("core.base.option")
        import("core.project.config")
        import("core.tool.compiler")

        -- get rcc
        local rcc = target:data("qt.rcc")

        -- get c++ source file for qrc
        local sourcefile_cpp = path.join(config.buildir(), ".qt", "qrc", target:name(), path.basename(sourcefile_qrc) .. ".cpp")
        local sourcefile_dir = path.directory(sourcefile_cpp)
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- trace
        if option.get("verbose") then
            print("%s -name qml %s -o %s", rcc, sourcefile_qrc, sourcefile_cpp)
        end

        -- compile qrc 
        os.runv(rcc, {"-name", "qml", sourcefile_qrc, "-o", sourcefile_cpp})

        -- get object file
        local objectfile = target:objectfile(sourcefile_cpp)

        -- trace
        if option.get("verbose") then
            print(compiler.compcmd(sourcefile_cpp, objectfile, {target = target}))
        end

        -- compile c++ source file for qrc
        compiler.compile(sourcefile_cpp, objectfile, {target = target})

        -- add objectfile
        table.insert(target:objectfiles(), objectfile)

        -- add clean files
        target:data_set("qt.qrc.cleanfiles", {sourcefile_cpp, objectfile})
    end)

    -- clean files
    after_clean(function (target)
        for _, file in ipairs(target:data("qt.qrc.cleanfiles")) do
            os.rm(file)
        end
        target:data_set("qt.qrc.cleanfiles", nil)
    end)

-- define rule: qt quick application
rule("qt.quickapp")

    -- add rules
    add_deps("qt.qrc")

    -- on load
    on_load(function (target)
        import("load")(target, {kind = "binary", frameworks = {"QtQuick", "QtGui", "QtQml", "QtNetwork", "QtCore"}})
    end)
