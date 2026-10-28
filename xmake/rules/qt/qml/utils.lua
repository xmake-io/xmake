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

-- imports
import("core.base.semver")
import("lib.detect.find_file")

-- get the qt sdk data of the target
function get_qt(target)
    return assert(target:data("qt"), "Qt not found!")
end

-- get the qt sdk version
function get_sdkver(target)
    local qt = get_qt(target)
    return assert(qt.sdkver and semver.new(qt.sdkver),
        "Qt SDK version not found, please run `xmake f --qt_sdkver=xxx` to set it.")
end

-- get the last value set by add_values()
function get_value(target, name)
    local values = target:values(name)
    if type(values) == "table" then
        return values[#values]
    end
    return values
end

-- get the last value or the given default value
function get_option(target, name, default)
    local value = get_value(target, name)
    if value == nil then
        return default
    end
    return value
end

-- get all values set by add_values()
function get_values(target, name)
    local values = {}
    for _, value in ipairs(table.wrap(target:values(name))) do
        table.insert(values, value)
    end
    return values
end

-- get the extra QML import directories
function get_imports(target)
    local imports = {}
    for _, value in ipairs(table.wrap(target:values("qt.qml.import"))) do
        table.join2(imports, table.wrap(value))
    end
    return imports
end

-- get the module settings
function get_setting(target)
    local setting = {
        uri          = get_option(target, "qt.qml.uri", target:name()),
        cachegen     = get_option(target, "qt.qml.cachegen", true),
        only_bytecode = get_option(target, "qt.qml.only_bytecode", false),
        type_compiler = get_option(target, "qt.qml.type_compiler", false),
        namespace    = get_option(target, "qt.qml.namespace", ""),
        discard      = get_option(target, "qt.qml.discard", false),
        aot_stats    = get_value(target, "qt.qml.aot_stats"),
        imports      = get_imports(target)
    }
    -- only bytecode also requires the qmlcachegen toolchain
    if setting.only_bytecode then
        setting.cachegen = true
    end
    return setting
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

-- get the resource path of the given alias, e.g. /qt/qml/MyApp/Main.qml
function get_resource_path(uri, alias)
    return get_prefix(uri) .. alias
end

-- get the absolute path of the given source file
function get_absfile(target, sourcefile)
    if path.is_absolute(sourcefile) then
        return path.normalize(sourcefile)
    end
    return path.normalize(path.absolute(sourcefile, os.projectdir()))
end

-- is the given file inside the given directory?
function _is_inside(absfile, dir)
    local rel = path.relative(absfile, dir)
    local relunix = path.unix(rel)
    return not path.is_absolute(rel) and relunix ~= ".." and not relunix:startswith("../")
end

-- get the resource alias, it is relative to the target script directory
function get_alias(target, sourcefile)
    local scriptdir = path.absolute(target:scriptdir())
    local projectdir = path.absolute(os.projectdir())
    local absfile = get_absfile(target, sourcefile)
    if _is_inside(absfile, scriptdir) then
        return path.unix(path.relative(absfile, scriptdir)), absfile
    end
    -- the file is outside of the module directory, use the project directory
    -- to keep the alias valid and warn the user
    local alias = path.unix(path.relative(absfile, projectdir))
    wprint("qt.qml: %s is outside of the module directory(%s), packing it with alias '%s'",
        sourcefile, path.unix(scriptdir), alias)
    return alias, absfile
end

-- get the mangled name of the given file, e.g. src/Main.qml -> src/Main_qml
function get_mangled_name(target, sourcefile)
    local absfile = get_absfile(target, sourcefile)
    local scriptdir = path.absolute(target:scriptdir())
    local name
    if _is_inside(absfile, scriptdir) then
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
    return (get_mangled_name(target, sourcefile):gsub("/", "_"))
end

-- get the qmlcachegen/qmltc output file, e.g. <autogendir>/rules/qt/qmlcachegen/src/Main_qml.cpp
function get_autogen_file(target, dir, sourcefile, extension)
    local autogendir = path.absolute(target:autogendir())
    return path.join(autogendir, "rules", "qt", dir, get_mangled_name(target, sourcefile) .. extension)
end

-- get the tool search directories, we must only search the selected SDK
function get_tool_dirs(target)
    local qt = get_qt(target)
    local dirs = {}
    for _, dir in ipairs({qt.libexecdir_host, qt.bindir_host, qt.libexecdir, qt.bindir}) do
        if dir and not table.contains(dirs, dir) then
            table.insert(dirs, dir)
        end
    end
    return dirs
end

-- find a tool from the selected SDK only
function find_tool(target, name)
    local cachekey = "qt.qml.tool." .. name
    local tool = target:data(cachekey)
    if tool == nil then
        local filename = is_host("windows") and (name .. ".exe") or name
        tool = find_file(filename, get_tool_dirs(target)) or false
        if tool and not os.isexec(tool) then
            tool = false
        end
        target:data_set(cachekey, tool)
    end
    return tool or nil
end

-- find rcc, used when the qt.qrc rule is not a target rule
function find_rcc(target)
    local rcc = target:data("qt.rcc")
    if not rcc then
        local qt = get_qt(target)
        local dirs = {}
        for _, dir in ipairs({qt.bindir_host, qt.bindir, qt.libexecdir_host, qt.libexecdir}) do
            if dir and not table.contains(dirs, dir) then
                table.insert(dirs, dir)
            end
        end
        local filename = is_host("windows") and "rcc.exe" or "rcc"
        rcc = find_file(filename, dirs)
        if rcc and os.isexec(rcc) then
            target:data_set("qt.rcc", rcc)
        else
            rcc = nil
        end
    end
    return rcc
end

-- get the version of the given tool
function get_tool_version(tool)
    local outdata = try
    {
        function ()
            return os.iorunv(tool, {"--version"})
        end
    }
    local version = outdata and outdata:match("(%d+%.%d+%.%d+)")
    return version and semver.new(version)
end

-- check the tool version against the qt sdk version
function check_tool_version(target, tool, name)
    local sdkver = get_sdkver(target)
    local version = get_tool_version(tool)
    if not version then
        wprint("qt.qml: cannot get the version of %s(%s)", name, tool)
        return
    end
    assert(version:major() == sdkver:major(),
        "qt.qml: %s(%s) version(%s) does not match the Qt SDK version(%s), please check your Qt SDK!",
        name, tool, tostring(version), tostring(sdkver))
    if version:minor() ~= sdkver:minor() then
        wprint("qt.qml: %s version(%s) differs from the Qt SDK version(%s)", name, tostring(version), tostring(sdkver))
    end
end

-- does the tool support the given option? e.g. --only-bytecode
function has_tool_option(target, tool, option)
    local cachekey = "qt.qml.tooloption." .. tool .. "." .. option
    local supported = target:data(cachekey)
    if supported == nil then
        local helpdata = try
        {
            function ()
                return os.iorunv(tool, {"--help"})
            end
        }
        supported = helpdata and helpdata:find(option, 1, true) ~= nil or false
        target:data_set(cachekey, supported)
    end
    return supported
end

-- get the moc flags of the target
function get_moc_flags(target)
    import("core.tool.compiler")

    local function _get_values_from_target(name)
        local values = {}
        for _, value in ipairs((target:get_from(name, "*"))) do
            table.join2(values, value)
        end
        return table.unique(values)
    end

    local flags = {}
    table.join2(flags, compiler.map_flags("cxx", "define", _get_values_from_target("defines")))
    for _, item in ipairs(_get_values_from_target("includedirs")) do
        table.insert(flags, "-I" .. path.unix(item))
    end
    for _, item in ipairs(_get_values_from_target("sysincludedirs")) do
        table.insert(flags, "-I" .. path.unix(item))
    end
    for _, item in ipairs(_get_values_from_target("frameworkdirs")) do
        table.insert(flags, "-F" .. path.unix(item))
    end
    return flags
end
