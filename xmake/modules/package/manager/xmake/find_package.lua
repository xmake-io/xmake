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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_package.lua
--

-- imports
import("core.base.global")
import("core.project.config")
import("core.project.option")
import("core.project.target")
import("core.package.package")
import("core.language.language")
import("lib.detect.find_file")
import("lib.detect.find_library")

-- find package from the repository (maybe only include and no links)
function _find_package_from_repo(name, opt)

    -- check options
    if not opt.version or not opt.buildhash then
        return
    end

    -- find the manifest file of package, e.g. ~/.xmake/packages/z/zlib/1.1.12/ed41d5327fad3fc06fe376b4a94f62ef/manifest.txt
    local packagedirs = {}
    table.insert(packagedirs, path.join(package.installdir(), name:lower():sub(1, 1), name:lower(), opt.version, opt.buildhash))
    local manifest_file = find_file("manifest.txt", packagedirs)
    if not manifest_file then
        return
    end

    -- load manifest info
    local manifest = io.load(manifest_file)
    if not manifest then
        return
    end

    -- get manifest variables
    local vars = manifest.vars or {}

    -- get install directory of this package
    local installdir = path.directory(manifest_file)

    -- save includedirs to result (maybe only include and no links)
    local result = {}
    local includedirs = {}
    for _, includedir in ipairs(vars.includedirs) do
        table.insert(includedirs, path.join(installdir, includedir))
    end
    if #includedirs == 0 and os.isdir(path.join(installdir, "include")) then
        table.insert(includedirs, path.join(installdir, "include"))
    end
    if #includedirs > 0 then
        result.includedirs = table.unique(includedirs)
    end

    -- get links and link directories
    local links = {}
    local linkdirs = {}
    local libfiles = {}
    for _, linkdir in ipairs(vars.linkdirs) do
        table.insert(linkdirs, path.join(installdir, linkdir))
    end
    if vars.links then
        table.join2(links, vars.links)
    end
    if not vars.linkdirs or not vars.links then
        local found = false
        for _, file in ipairs(os.files(path.join(installdir, "lib", "*"))) do
            if file:endswith(".lib") or file:endswith(".a") then
                found = true
                if not vars.linkdirs then
                    table.insert(linkdirs, path.directory(file))
                end
                if not vars.links then
                    table.insert(links, target.linkname(path.filename(file)))
                end
            end
        end
        if not found then
            for _, file in ipairs(os.files(path.join(installdir, "lib", "*"))) do
                if file:endswith(".so") or file:endswith(".dylib") then
                    if not vars.linkdirs then
                        table.insert(linkdirs, path.directory(file))
                    end
                    if not vars.links then
                        table.insert(links, target.linkname(path.filename(file)))
                    end
                end
            end
        end
    end
    if opt.plat == "windows" then
        for _, file in ipairs(os.files(path.join(installdir, "lib", "*.dll"))) do
            table.insert(libfiles, file)
        end
        for _, file in ipairs(os.files(path.join(installdir, "bin", "*.dll"))) do
            table.insert(libfiles, file)
        end
    end

    -- add root link directories
    if #linkdirs == 0 then
        table.insert(linkdirs, path.join(installdir, "lib"))
    end

    -- uses name as links directly e.g. libname.a
    if #links == 0 then
        links = table.wrap(name)
    end

    -- find library
    for _, link in ipairs(links) do
        local libinfo = find_library(link, linkdirs)
        if libinfo then
            result.links     = table.join(result.links or {}, libinfo.link)
            result.linkdirs  = table.join(result.linkdirs or {}, libinfo.linkdir)
            result.libfiles = table.join(result.libfiles or {}, path.join(libinfo.linkdir, libinfo.filename))
        end
    end
    if result.links then
        result.links = table.unique(result.links)
    end
    if result.libfiles then
        result.libfiles = table.join(result.libfiles, libfiles)
    end

    -- inherit the other prefix variables
    for name, values in pairs(vars) do
        if name ~= "links" and name ~= "linkdirs" and name ~= "includedirs" then
            result[name] = values
        end
    end

    -- update the project references file
    if result then
        local projectdir = os.projectdir()
        if projectdir and os.isdir(projectdir) then
            local references_file = path.join(installdir, "references.txt")
            local references = os.isfile(references_file) and io.load(references_file) or {}
            references[projectdir] = os.date("%y%m%d")
            io.save(references_file, references)
        end
    end

    -- get version
    result.version = manifest.version or path.filename(path.directory(path.directory(manifest_file)))
    return result
end

-- find package from the package directories
function _find_package_from_packagedirs(name, opt)

    -- get package path (e.g. name.pkg) in the package directories
    local packagepath = nil
    for _, dir in ipairs(table.wrap(opt.packagedirs)) do
        local p = path.join(dir, name .. ".pkg")
        if os.isdir(p) then
            packagepath = p
            break
        end
    end
    if not packagepath then
        return
    end

    -- get package file (e.g. name.pkg/xmake.lua)
    local packagefile = path.join(packagepath, "xmake.lua")
    if not os.isfile(packagefile) then
        return
    end

    -- init interpreter
    local interp = option.interpreter()

    -- register filter handler
    interp:filter():register("find_package", function (variable)

        -- init maps
        local maps =
        {
            arch       = opt.arch
        ,   plat       = opt.plat
        ,   mode       = opt.mode
        }

        -- get variable
        return maps[variable]
    end)

    -- load script
    local ok, errors = interp:load(packagefile)
    if not ok then
        raise(errors)
    end

    -- load the package from the the package file
    local packageinfos, errors = interp:make("option", true, true)
    if not packageinfos then
        raise(errors)
    end

    -- unregister filter handler
    interp:filter():register("find_package", nil)

    -- get package info
    local packageinfo = packageinfos[name]
    if not packageinfo then
        return
    end

    -- get linkdirs
    local linkdirs = {}
    for _, linkdir in ipairs(packageinfo:get("linkdirs")) do
        table.insert(linkdirs, path.join(packagepath, linkdir))
    end
    if #linkdirs == 0 then
        return
    end

    -- find library
    local result = nil
    for _, link in ipairs(packageinfo:get("links")) do
        local libinfo = find_library(link, linkdirs)
        if libinfo then
            result          = result or {}
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
            result.libfiles = table.join(result.libfiles or {}, path.join(libinfo.linkdir, libinfo.filename))
        end
    end

    -- inherit other package info
    if result then
        result.includedirs = {}
        for _, includedir in ipairs(packageinfo:get("includedirs")) do
            table.insert(result.includedirs, path.join(packagepath, includedir))
        end
        for _, infoname in ipairs({"defines", "languages", "warnings"}) do
            result[infoname] = packageinfo:get(infoname)
        end
    end

    -- ok?
    return result
end

-- find package using the xmake package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x", buildhash = "xxxxxx")
--
function main(name, opt)

    -- find package from repository
    local result = _find_package_from_repo(name, opt)

    -- find package from the given package directories, e.g. packagedir/xxx.pkg
    if not result and opt.packagedirs then
        result = _find_package_from_packagedirs(name, opt)
    end
    return result
end
