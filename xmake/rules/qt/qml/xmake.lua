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
-- @author      24bit-xjkp
-- @file        xmake.lua
--

-- It packs the module resources and compiles them with the qt.qrc rule.
--
-- Qt treats only `.qml`, `.js` and `.mjs` as QML files, all other files passed
-- to a module are resources (RESOURCES), see:
-- https://doc.qt.io/qt-6/qt-add-qml-module.html
--
-- We only dispatch the resource formats commonly used by Qt Quick applications,
-- so that arbitrary files are not silently packed into the QML module:
--
-- - images: QImageReader and the Qt Image Formats module
--   https://doc.qt.io/qt-6/qimagereader.html#supportedImageFormats
--   https://doc.qt.io/qt-6/qtimageformats-index.html
-- - fonts: QFontDatabase supports TrueType, TrueType collections and OpenType
--   https://doc.qt.io/qt-6/qfontdatabase.html
-- - shaders: ShaderEffect expects the packaged .qsb files in Qt 6
--   https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html
-- - translations: the compiled .qm files
-- - multimedia: the container formats of QMediaFormat
--   https://doc.qt.io/qt-6/qmediaformat.html
-- - 3D: the runtime .mesh files of Qt Quick 3D
-- - data: the JSON/text files commonly loaded from the resource system
rule("qt.qml.resource")
    -- qt.qrc provides the rcc tool for the generated resource qrc
    add_deps("qt.qrc")

    -- the resource qrc must exist before qt.qml passes it to qmlcachegen
    add_orders("qt.qml.resource", "qt.qml")

    set_extensions(
        -- images
        ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".svg", ".svgz", ".pbm", ".pgm", ".ppm",
        ".xbm", ".xpm", ".ico", ".icns", ".tga", ".tif", ".tiff", ".wbmp", ".webp", ".jp2", ".mng",
        -- fonts
        ".ttf", ".ttc", ".otf", ".otc",
        -- shaders
        ".qsb",
        -- translations
        ".qm",
        -- multimedia
        ".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma", ".mp4", ".avi", ".mkv",
        ".mov", ".webm", ".wmv",
        -- Qt Quick 3D
        ".mesh",
        -- data
        ".json", ".txt"
    )

    -- The resource qrc is written synchronously in the prepare phase, so it already
    -- exists when it is added to the target and no `always_added` is needed.
    before_preparecmd_files("prepare_resource")

-- It packs the QML module sources and compiles them with qmlcachegen.
--
-- The rule can be used directly by users together with the qt.quickapp rule (which
-- provides the Qt includes/links), e.g.:
--
-- target("app")
--     add_rules("qt.quickapp", "qt.qml", "qt.qml.resource")
--     add_files("*.qml", "*.js", "*.mjs")
--     add_values("qt.qml.uri", "MyApp")
--
-- The extra QML import directories are passed with
-- `add_values("qt.qml.import", "<dir>")`.
rule("qt.qml")
    -- qt.env provides the Qt SDK, qt.qrc provides the rcc tool for the generated qrc
    add_deps("qt.env", "qt.qrc")
    set_extensions(".qml", ".js", ".mjs")

    on_load("load")
    on_config("config")

    -- The prepare phase is split into the standard stages:
    --   before: write the module qrc and generate the qmlcache_loader
    --   on:     run qmlcachegen for each source file
    --   after:  register the generated files to the target
    --
    -- Every file gets its own batchcmds from `on_preparecmd_file`, so the files are
    -- still generated in parallel and no jobgraph is needed for qmlcachegen alone.
    before_preparecmd_files(function (target, batchcmds, sourcebatch, opt)
        import("prepare_qml").before_prepare(target, batchcmds, sourcebatch, opt)
    end)
    on_preparecmd_file(function (target, batchcmds, sourcefile, opt)
        import("prepare_qml").on_preparecmd_file(target, batchcmds, sourcefile, opt)
    end)
    after_preparecmd_files(function (target, batchcmds, sourcebatch, opt)
        import("prepare_qml").after_prepare(target, batchcmds, sourcebatch, opt)
    end)
