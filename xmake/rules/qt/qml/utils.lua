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
-- @file        utils.lua
--

import("core.base.semver")
import("lib.detect.find_tool")
import("lib.detect.has_flags")

-- get the qt sdk data of the target, it is provided by the qt.env rule
function get_qt(target)
    return assert(target:data("qt"), "Qt not found!")
end

-- get the qt sdk version
function get_sdkver(target)
    local qt = get_qt(target)
    return assert(qt.sdkver and semver.new(qt.sdkver), "Qt SDK version not found.")
end

-- get the last value set by add_values()
function get_option(target, name, default)
    local values = target:values(name)
    if type(values) == "table" then
        values = values[#values]
    end
    if values == nil then
        return default
    end
    return values
end

-- get the module settings
function get_setting(target)
    local setting = {
        uri           = get_option(target, "qt.qml.uri", target:name()),
        cachegen      = get_option(target, "qt.qml.cachegen", true),
        only_bytecode = get_option(target, "qt.qml.only_bytecode", false),
        type_compiler = get_option(target, "qt.qml.type_compiler", false),
        namespace     = get_option(target, "qt.qml.namespace"),
        discard       = get_option(target, "qt.qml.discard", false),
        aot_stats     = get_option(target, "qt.qml.aot_stats"),
        imports       = {}
    }
    for _, value in ipairs(table.wrap(target:values("qt.qml.import"))) do
        table.join2(setting.imports, table.wrap(value))
    end
    -- qmlcachegen is required by only_bytecode, ignore it when cachegen is disabled,
    -- load.lua warns the user about it
    if setting.only_bytecode == true and not setting.cachegen then
        setting.only_bytecode = false
    end
    return setting
end

-- classify the source files and get the generators needed by the module
--
-- A module which only contains the qmldir file needs no generator, and qmltc only
-- compiles the .qml files.
function get_needs(setting, sourcefiles)
    local needs = { cachegen = false, type_compiler = false }
    for _, sourcefile in ipairs(sourcefiles) do
        local filename = path.filename(sourcefile):lower()
        if filename ~= "qmldir" and path.extension(filename) ~= ".qmldir" then
            needs.cachegen = true
            if path.extension(filename) == ".qml" then
                needs.type_compiler = true
            end
        end
    end
    needs.cachegen = needs.cachegen and setting.cachegen
    needs.type_compiler = needs.type_compiler and setting.type_compiler
    return needs
end

-- check the QML module uri
function check_uri(uri)
    assert(type(uri) == "string" and #uri > 0, "qt.qml: the module uri must be a non-empty string!")
    assert(not uri:find("/", 1, true), "qt.qml: invalid module uri(%s), it cannot contain '/'!", uri)
    assert(not uri:find("%s"), "qt.qml: invalid module uri(%s), it cannot contain whitespace!", uri)
end

-- get the resource prefix of the QML module, e.g. /qt/qml/MyApp/
function get_prefix(uri)
    return "/qt/qml/" .. uri:gsub("%.", "/") .. "/"
end

-- get the absolute path of the given source file
function get_absfile(sourcefile)
    if path.is_absolute(sourcefile) then
        return path.normalize(sourcefile)
    end
    return path.normalize(path.absolute(sourcefile, os.projectdir()))
end

-- is the given file inside the given directory?
function is_inside(absfile, dir)
    local rel = path.unix(path.relative(absfile, dir))
    return not path.is_absolute(rel) and rel ~= ".." and not rel:startswith("../")
end

-- get the resource alias, it is relative to the target script directory
function get_alias(target, sourcefile)
    local scriptdir = path.absolute(target:scriptdir())
    local projectdir = path.absolute(os.projectdir())
    local absfile = get_absfile(sourcefile)
    if is_inside(absfile, scriptdir) then
        return path.unix(path.relative(absfile, scriptdir)), absfile
    end
    -- the file is outside of the module directory, use the project directory
    -- to keep the alias valid and warn the user
    local alias = path.unix(path.relative(absfile, projectdir))
    wprint(
        "qt.qml: %s is outside of the module directory(%s), packing it with alias '%s'", sourcefile,
        path.unix(scriptdir), alias
    )
    return alias, absfile
end

-- get the mangled name of the given file, e.g. src/Main.qml -> src/Main_qml
function get_mangled_name(target, sourcefile)
    local absfile = get_absfile(sourcefile)
    local scriptdir = path.absolute(target:scriptdir())
    ---@type string
    local name
    if is_inside(absfile, scriptdir) then
        name = path.unix(path.relative(absfile, scriptdir))
    else
        name = hash.strhash32(absfile) .. "_" .. path.filename(absfile)
    end
    local extension = path.extension(name)
    if extension ~= "" then
        name = name:sub(1, #name - #extension) .. "_" .. extension:sub(2)
    end
    return name
end

-- get the flat qmltc file name, qmltc includes the generated headers by their file name only
function get_qmltc_name(target, sourcefile)
    local name = get_mangled_name(target, sourcefile)
    if name:find("/", 1, true) then
        -- the path separators are flattened, append a hash to keep the names unique,
        -- e.g. a/b.qml and a_b.qml would collide without it
        name = (name:gsub("/", "_")) .. "_" .. hash.strhash32(name)
    end
    return name
end

-- get the qmlcachegen/qmltc output file, e.g. <autogendir>/rules/qt/qmlcachegen/src/Main_qml.cpp
function get_autogen_file(target, dir, sourcefile, extension)
    local autogendir = path.absolute(target:autogendir())
    return path.join(autogendir, "rules", "qt", dir, get_mangled_name(target, sourcefile) .. extension)
end

-- get the generated files and directories of the QML module
function get_paths(target)
    local autogendir = path.absolute(target:autogendir())
    local gendir = path.join(autogendir, "rules", "qt", "qml")
    local cachegendir = path.join(autogendir, "rules", "qt", "qmlcachegen")
    local qmltcdir = path.join(autogendir, "rules", "qt", "qmltc")
    return {
        qrcfile      = path.join(gendir, "qml_module.qrc"),
        resourceqrc  = path.join(gendir, "qml_resource.qrc"),
        loadercpp    = path.join(cachegendir, target:name() .. "_qmlcache_loader.cpp"),
        aotstats     = path.join(cachegendir, target:name() .. ".aotstats"),
        aotstatstxt  = path.join(cachegendir, target:name() .. ".aotstats.txt"),
        aotstatslist = path.join(cachegendir, target:name() .. ".aotstatslist"),
        qmltcdir     = qmltcdir,
        qmltcmap     = path.join(qmltcdir, "qmltc_file_map.qrc")
    }
end

-- get the QML import directories, e.g. <qt>/qml and the user defined directories
function get_importdirs(target, setting)
    local qt = get_qt(target)
    local dirs = {}
    if qt.qmldir then
        table.insert(dirs, qt.qmldir)
    end
    table.join2(dirs, setting.imports)
    return dirs
end

-- get the tool search directories, we only search the selected SDK
function get_tool_dirs(target)
    local qt = get_qt(target)
    local dirs = {}
    local function _add(dir)
        if dir and not table.contains(dirs, dir) then
            table.insert(dirs, path.absolute(dir))
        end
    end
    -- host tools first, e.g. for cross compilation
    _add(qt.libexecdir_host)
    _add(qt.bindir_host)
    _add(qt.libexecdir)
    _add(qt.bindir)
    return dirs
end

-- is the given tool inside the SDK directories?
function _is_in_tool_dirs(tool, dirs)
    local absfile = path.absolute(tool)
    for _, dir in ipairs(dirs) do
        if is_inside(absfile, dir) then
            return true
        end
    end
    return false
end

-- find a tool in the selected SDK only
--
-- The detection result is cached by xmake's detect cache, we use a cachekey derived
-- from the SDK version and directories, so that multiple Qt SDKs in the same project
-- do not mix up their tools.
function find_sdk_tool(target, name)
    local qt = get_qt(target)
    local dirs = get_tool_dirs(target)
    local opt = {
        paths = dirs,
        cachekey = "qt.qml." .. (qt.sdkver or "") .. "." .. hash.strhash32(table.concat(dirs, "|"))
    }
    if name == "qmlcachegen" or name == "qmltc" then
        opt.version = true
    else
        -- qmlimportscanner/qmlaotstats do not support `--version`
        opt.norun = true
    end
    local tool = find_tool(name, opt)
    if tool and tool.program then
        -- find_program will fall back to PATH if the tool is not found in the given
        -- directories, we must reject these tools because they may belong to another
        -- Qt SDK version
        if not _is_in_tool_dirs(tool.program, dirs) then
            return
        end
        tool.name = tool.name or name
    end
    return tool
end

-- check the tool version against the qt sdk version
function check_tool_version(target, tool, name)
    local sdkver = get_sdkver(target)
    local version = tool.version and semver.new(tool.version)
    if not version then
        wprint("qt.qml: cannot get the version of %s(%s)", name, tool.program)
        return
    end
    assert(
        version:major() == sdkver:major(),
        "qt.qml: %s(%s) version(%s) does not match the Qt SDK version(%s), please check your Qt SDK!", name,
        tool.program, tostring(version), tostring(sdkver)
    )
    if version:minor() ~= sdkver:minor() then
        wprint("qt.qml: %s version(%s) differs from the Qt SDK version(%s)", name, tostring(version), tostring(sdkver))
    end
end

-- does the tool support the given option(s)? e.g. --only-bytecode
function has_tool_option(tool, flags)
    -- we also pass `version = true` so that the detect cache is invalidated when the
    -- SDK is upgraded in place
    return has_flags(tool.name, flags, { program = tool.program, version = true })
end

-- find the tools required by the module settings
--
-- @param needs  the generators needed by the module, see get_needs(), e.g.
--               {cachegen = true, type_compiler = false}
function get_tools(target, setting, needs)
    -- a module which only contains the qmldir file needs no tool at all
    if not (needs.cachegen or needs.type_compiler) then
        return {}
    end
    local sdkver = get_sdkver(target)
    local dirs = get_tool_dirs(target)
    local tools = {}
    if needs.cachegen then
        assert(sdkver:ge("6.2"), "qt.qml: qmlcachegen requires Qt >= 6.2, please disable it with {cachegen = false}")
        tools.cachegen = assert(
            find_sdk_tool(target, "qmlcachegen"), "qt.qml: qmlcachegen not found in the Qt SDK(%s)",
            table.concat(dirs, ", ")
        )
        check_tool_version(target, tools.cachegen, "qmlcachegen")
        if setting.only_bytecode then
            assert(
                has_tool_option(tools.cachegen, "--only-bytecode"),
                "qt.qml: qmlcachegen(%s) does not support --only-bytecode", tools.cachegen.program
            )
        end
    end
    if needs.type_compiler then
        assert(sdkver:ge("6.4"), "qt.qml: qmltc requires Qt >= 6.4, please disable it with {type_compiler = false}")
        tools.qmltc = assert(
            find_sdk_tool(target, "qmltc"), "qt.qml: qmltc not found in the Qt SDK(%s)", table.concat(dirs, ", ")
        )
        check_tool_version(target, tools.qmltc, "qmltc")
    end
    if needs.cachegen or needs.type_compiler then
        -- the import scanner provides the dependency graph of the module
        tools.importscanner = assert(
            find_sdk_tool(target, "qmlimportscanner"), "qt.qml: qmlimportscanner not found in the Qt SDK(%s)",
            table.concat(dirs, ", ")
        )
    end
    return tools
end

-- resolve the AOT statistics settings
--
-- @param needs  the generators needed by the module, the AOT report requires qmlcachegen
function get_aot(target, setting, tools, needs)
    local aot = { enabled = false }
    if setting.aot_stats == false then
        return aot
    end
    if needs.cachegen and not setting.only_bytecode then
        aot.tool = find_sdk_tool(target, "qmlaotstats")
        -- --dump-aot-stats also requires --module-id, otherwise qmlcachegen exits with an error
        local supported = has_tool_option(tools.cachegen, { "--dump-aot-stats", "--module-id=qt.qml" })
        if setting.aot_stats == true then
            assert(
                aot.tool,
                "qt.qml: qt.qml.aot_stats is enabled, but qmlaotstats is not found "
                    .. "(requires Qt >= 6.8), please disable it with {aot_stats = false}"
            )
            assert(supported, "qt.qml: qmlcachegen(%s) does not support --dump-aot-stats", tools.cachegen.program)
            aot.enabled = true
        elseif setting.aot_stats == nil then
            aot.enabled = supported and aot.tool ~= nil
        end
    elseif setting.aot_stats == true then
        -- the caller reports the warning, so it is not printed again by every prepare job
        aot.ignored = true
    end
    return aot
end
