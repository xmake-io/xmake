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
import("lib.detect.find_tool")
import("lib.detect.has_flags")

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
        version       = get_option(target, "qt.qml.version", "1.0"),
        cachegen      = get_option(target, "qt.qml.cachegen", true),
        only_bytecode = get_option(target, "qt.qml.only_bytecode", false),
        type_compiler = get_option(target, "qt.qml.type_compiler", false),
        namespace     = get_option(target, "qt.qml.namespace"),
        discard       = get_option(target, "qt.qml.discard", false),
        aot_stats     = get_option(target, "qt.qml.aot_stats"),
        imports       = {}
    }
    for _, importdir in ipairs(target:values("qt.qml.import")) do
        -- relative import directories are declared in the target script, e.g.
        -- sub/xmake.lua, so resolve them against the script directory instead
        -- of the project root before passing them to the QML tools
        table.insert(setting.imports, path.absolute(importdir, target:scriptdir()))
    end
    -- qmlcachegen is required by only_bytecode, ignore it when cachegen is disabled,
    -- load.lua warns the user about it
    if setting.only_bytecode == true and not setting.cachegen then
        setting.only_bytecode = false
    end
    return setting
end

-- is the given file compiled by qmltc?
function is_qmltc_file(sourcefile)
    return path.extension(sourcefile):lower() == ".qml"
end

-- get the resource prefix of the QML module, e.g. /qt/qml/MyApp/
function get_prefix(uri)
    return "/qt/qml/" .. uri:gsub("%.", "/") .. "/"
end

-- is the given file inside the given directory?
function is_inside(absfile, dir)
    local rel = path.relative(absfile, dir)
    return not path.is_absolute(rel) and not rel:startswith("..")
end

-- get the resource alias, it is relative to the target script directory
function get_alias(target, sourcefile)
    local scriptdir = target:scriptdir()
    local projectdir = os.projectdir()
    local absfile = path.absolute(sourcefile, projectdir)
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

-- get the autogen directory of the given generator
function get_autogen_dir(target, name)
    return path.join(path.absolute(target:autogendir(), os.projectdir()), "rules", "qt", name)
end

-- get the generated file of the given source file, e.g.
-- <autogendir>/rules/qt/qmlcachegen/src/Main.qml.cpp
--
-- The source file name is kept as-is, so the generated header of `Main.qml` is
-- `Main.qml.h`. `opt.flat` flattens the source path and appends a hash to the
-- file name, qmltc includes the generated headers by their file name only.
function get_autogen_file(target, dir, sourcefile, extension, opt)
    opt = opt or {}
    local absfile = path.absolute(sourcefile, os.projectdir())
    local scriptdir = target:scriptdir()
    ---@type string
    local name
    if is_inside(absfile, scriptdir) then
        name = path.unix(path.relative(absfile, scriptdir))
    else
        name = hash.strhash32(absfile) .. "_" .. path.filename(absfile)
    end
    if opt.flat and name:find("/", 1, true) then
        name = name:gsub("/", "_") .. "_" .. hash.strhash32(name)
    end
    return path.join(get_autogen_dir(target, dir), name .. extension)
end

-- get the module files in a stable order
function get_file_list(files)
    local sourcefiles = table.keys(files)
    table.sort(sourcefiles)
    local filelist = {}
    for _, sourcefile in ipairs(sourcefiles) do
        table.insert(filelist, files[sourcefile])
    end
    return filelist
end

-- get the generated files and directories of the QML module
function get_paths(target)
    local gendir = get_autogen_dir(target, "qml")
    -- use the target fullname in the qrc file names, otherwise the rcc generated
    -- symbols collide when one executable links multiple QML module targets
    local name = hash.strhash32(target:fullname())
    return {
        qrcfile     = path.join(gendir, "qml_module_" .. name .. ".qrc"),
        resourceqrc = path.join(gendir, "qml_resource_" .. name .. ".qrc")
    }
end

-- is the given tool inside the SDK directories?
function _is_in_tool_dirs(tool, dirs)
    for _, dir in ipairs(dirs) do
        if is_inside(tool, dir) then
            return true
        end
    end
    return false
end

-- find a tool in the selected SDK only
function find_sdk_tool(target, name)
    local qt = target:data("qt")
    -- host tools first, e.g. for cross compilation, the SDK may not provide all
    -- directories (e.g. a host libexecdir for a native Qt build)
    local dirs = {}
    for _, key in ipairs({ "libexecdir_host", "bindir_host", "libexecdir", "bindir" }) do
        if qt[key] then
            table.insert(dirs, qt[key])
        end
    end
    local opt = {
        paths = dirs,
        -- find_program caches results by tool name only by default. Include the SDK
        -- directories so that switching from SDK A to SDK B does not reuse A's cached
        -- program and then reject it in the directory check below.
        cachekey = "qt.qml." .. name .. "." .. hash.strhash32(table.concat(dirs, "\n"))
    }
    if name == "qmlcachegen" or name == "qmltc" then
        opt.version = true
    elseif name == "qmlaotstats" then
        -- qmlaotstats doesn't support `--version`, use `--help` to check it
        opt.check = "--help"
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

-- does the tool support the given option(s)? e.g. --only-bytecode
function has_tool_option(tool, flags)
    -- we also pass `version = true` so that the detect cache is invalidated when the
    -- SDK is upgraded in place
    return has_flags(tool.name, flags, { program = tool.program, version = true })
end

-- add the arguments shared by qmlcachegen and qmltc
function add_import_args(args, setup)
    for _, dir in ipairs(setup.importdirs) do
        table.insert(args, "-I")
        table.insert(args, dir)
    end
    -- The qmldir generated for qmltc also lets qmlcachegen resolve the types of
    -- the same module, Qt CMake passes it to both tools.
    if setup.need_qmltc then
        table.insert(args, "-i")
        table.insert(args, setup.qmltcpaths.qmldir)
    end
    for _, resource in ipairs(setup.resources) do
        table.insert(args, "--resource")
        table.insert(args, resource)
    end
end
