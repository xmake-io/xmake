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
-- @file        xmake.lua
--

function _build_wasm_app(target, qt, pluginsdir)
    local targetdir = target:targetdir()
    local htmlfile = path.join(targetdir, target:basename() .. ".html")
    if os.isfile(path.join(pluginsdir, "platforms/wasm_shell.html")) then
        os.vcp(path.join(pluginsdir, "platforms/wasm_shell.html"), htmlfile)
        io.gsub(htmlfile, "@APPNAME@", target:name())
        import("core.base.semver")
        local qt_sdkver = qt.sdkver or target:data("qt_sdkver")
        if qt_sdkver and semver.new(qt_sdkver):ge("6.0") then
            io.gsub(htmlfile, "@APPEXPORTNAME@", "createQtAppInstance")
            local preload = ""
            -- @see https://github.com/xmake-io/xmake/issues/6182
            local preloadfiles = target:values("wasm.preloadfiles")
            if preloadfiles then
                local filelist = {}
                for _, preloadfile in ipairs(preloadfiles) do
                    table.insert(filelist, string.format("'%s'", path.filename(preloadfile)))
                end
                if #filelist > 0 then
                    preload = string.format("preload: [%s],", table.concat(filelist, ", "))
                end
            end
            -- Patch old containerElements (pre-Qt 6.5)
            io.gsub(htmlfile, "containerElements: %[screen%],", function (w)
                return w .. " " .. preload
            end)
            -- Patch new qtContainerElements (Qt 6.5+)
            io.gsub(htmlfile, "qtContainerElements: %[screen%],", function (w)
                return w .. " " .. preload
            end)
            io.gsub(htmlfile, "@PRELOAD@", "")
            -- Fix Emscripten JS issues for Qt WASM builds
            local jsfile = path.join(targetdir, target:basename() .. ".js")
            if os.isfile(jsfile) then
                -- Remove "use strict"; to avoid issues with `this` being undefined in strict mode
                io.gsub(jsfile, "\"use strict\";", "")
                io.gsub(jsfile, "'use strict';", "")
                -- Patch visualViewport access issue if present (undefined this context)
                io.gsub(jsfile, "this%.visualViewport",
                    "(typeof window !== 'undefined' ? window.visualViewport : null)")
                -- Guard all document.querySelector(target) calls with try-catch.
                -- Qt WASM uses "!" prefixed selectors that are not valid CSS selectors,
                -- and corrupted strings from SharedArrayBuffer can also cause SyntaxErrors.
                io.gsub(jsfile, "document%.querySelector%(target%)",
                    "(function(){try{return document.querySelector(target)}catch(e){return null}})()")
                -- Replace findCanvasEventTarget with a robust version.
                -- Qt WASM registers canvases in Module.specialHTMLTargets with "!" prefixed
                -- keys (e.g. "!qtwindow1", "!qtoffscreen_xxx"). With pthreads +
                -- ALLOW_MEMORY_GROWTH, Emscripten's UTF8ToString may read corrupted strings
                -- from SharedArrayBuffer memory, causing the specialHTMLTargets lookup to fail.
                -- Additionally, QWasmOffscreenSurface passes an empty string when
                -- OffscreenCanvas is unavailable. The replacement adds a fallback that
                -- iterates specialHTMLTargets to find any Qt-registered canvas element.
                -- @see https://code.qt.io/cgit/qt/qtbase.git/tree/src/plugins/platforms/wasm/qwasmwindow.cpp
                -- @see https://code.qt.io/cgit/qt/qtbase.git/tree/src/plugins/platforms/wasm/qwasmoffscreensurface.cpp
                local content = io.readfile(jsfile)
                local marker = "var findCanvasEventTarget = target => {"
                local pos = content:find(marker, 1, true)
                if pos then
                    -- Find the end of the function by counting matched braces
                    local depth = 1
                    local i = pos + #marker
                    while i <= #content and depth > 0 do
                        local c = content:sub(i, i)
                        if c == "{" then depth = depth + 1
                        elseif c == "}" then depth = depth - 1 end
                        i = i + 1
                    end
                    if content:sub(i, i) == ";" then i = i + 1 end
                    local new_func = "var findCanvasEventTarget = target => {\n"
                        .. " target = maybeCStringToJsString(target);\n"
                        .. " if (specialHTMLTargets[target]) return specialHTMLTargets[target];\n"
                        .. " if (GL.offscreenCanvases[target]) return GL.offscreenCanvases[target];\n"
                        .. " if (typeof target === 'string' && target.length > 0) {\n"
                        .. "  var s = target.substr(1);\n"
                        .. "  if (GL.offscreenCanvases[s]) return GL.offscreenCanvases[s];\n"
                        .. " }\n"
                        .. " if (target === 'canvas') {\n"
                        .. "  var k = Object.keys(GL.offscreenCanvases);\n"
                        .. "  if (k.length) return GL.offscreenCanvases[k[0]];\n"
                        .. " }\n"
                        .. " for (var key in specialHTMLTargets) {\n"
                        .. "  if (typeof key === 'string' && key.charAt(0) === '!') {\n"
                        .. "   var el = specialHTMLTargets[key];\n"
                        .. "   if (el && (el.tagName === 'CANVAS' || (typeof OffscreenCanvas !== 'undefined' && el instanceof OffscreenCanvas))) return el;\n"
                        .. "  }\n"
                        .. " }\n"
                        .. " try { return typeof document !== 'undefined' ? document.querySelector(target) : undefined; }\n"
                        .. " catch(e) { return undefined; }\n"
                        .. "};\n"
                    content = content:sub(1, pos - 1) .. new_func .. content:sub(i)
                    io.writefile(jsfile, content)
                end
            end
        end
        os.vcp(path.join(pluginsdir, "platforms/qtloader.js"), targetdir)
        os.vcp(path.join(pluginsdir, "platforms/qtlogo.svg"), targetdir)
    end
end

-- define rule: qt/wasm application
rule("qt._wasm_app")
    add_deps("qt.env")
    after_build(function (target)
        local qt = target:data("qt")
        local pluginsdir = qt and qt.pluginsdir
        if pluginsdir then
            _build_wasm_app(target, qt, pluginsdir)
        end
    end)

-- define rule: qt static library
rule("qt.static")
    add_deps("qt.qrc", "qt.ui", "qt.moc", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", "static")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")
    add_deps("qt.qrc", "qt.ui", "qt.moc", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", "shared")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

-- define rule: qt console
rule("qt.console")
    add_deps("qt.qrc", "qt.ui", "qt.moc", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", "binary")
    end)

    on_config(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

-- define rule: qt widgetapp
rule("qt.widgetapp")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app", "qt.qrc", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)

        -- get qt sdk version
        local qt = target:data("qt")
        local qt_sdkver = nil
        if qt.sdkver then
            import("core.base.semver")
            qt_sdkver = semver.new(qt.sdkver)
        end

        local frameworks = {"QtGui", "QtWidgets", "QtCore"}
        if qt_sdkver and qt_sdkver:lt("5.0") then
            frameworks = {"QtGui", "QtCore"} -- qt4.x has not QtWidgets, it is in QtGui
        end
        import("load")(target, {gui = true, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

    -- install application for xpack
    on_installcmd("installcmd")
    on_uninstallcmd("uninstallcmd")

-- define rule: qt static widgetapp
rule("qt.widgetapp_static")
    add_deps("qt.ui", "qt.moc", "qt._wasm_app", "qt.qrc", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)
        local frameworks, plugins, qt_sdkver = import("config_static")(target)
        if qt_sdkver:ge("5.0") then
            table.join2(frameworks, {"QtGui", "QtWidgets", "QtCore"})
        else
            table.join2(frameworks, {"QtGui", "QtCore"})-- qt4.x has not QtWidgets, it is in QtGui
        end
        import("load")(target, {gui = true, plugins = plugins, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

    -- install application for xpack
    on_installcmd("installcmd")
    on_uninstallcmd("uninstallcmd")

-- define rule: qt quickapp
rule("qt.quickapp")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)
        import("load")(target, {gui = true, frameworks = {"QtGui", "QtQuick", "QtQml", "QtCore", "QtNetwork"}})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

    -- install application for xpack
    on_installcmd("installcmd")
    on_uninstallcmd("uninstallcmd")

-- define rule: qt static quickapp
rule("qt.quickapp_static")
    add_deps("qt.qrc", "qt.moc", "qt._wasm_app", "qt.ts")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)
        target:set("kind", target:is_plat("android") and "shared" or "binary")
    end)

    on_config(function (target)
        local frameworks, plugins = import("config_static")(target)
        table.join2(frameworks, {"QtGui", "QtQuick", "QtQml", "QtQmlModels", "QtCore", "QtNetwork"})
        import("load")(target, {gui = true, plugins = plugins, frameworks = frameworks})
    end)

    -- deploy application
    after_build("android", "deploy.android")
    after_build("macosx", "deploy.macosx")

    -- install application for android
    on_install("android", "install.android")
    after_install("windows", "install.windows")
    after_install("mingw", "install.mingw")

    -- install application for xpack
    on_installcmd("installcmd")
    on_uninstallcmd("uninstallcmd")

-- define rule: qt qmlplugin
rule("qt.qmlplugin")
    add_deps("qt.shared", "qt.qmltyperegistrar", "qt.ts")
    on_config(function(target)
        import("load")(target, {frameworks = { "QtCore", "QtGui", "QtQuick", "QtQml", "QtNetwork" }})
    end)

-- define rule: qt application (deprecated)
rule("qt.application")
    add_deps("qt.quickapp", "qt.ui")
