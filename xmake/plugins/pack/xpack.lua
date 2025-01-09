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
-- @author      ruki
-- @file        xpack.lua
--

-- imports
import("core.base.object")
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("private.core.base.select_script")
import("private.core.base.match_copyfiles")
import("lib.detect.find_tool")
import("filter")
import("xpack_component")

-- define module
local xpack = xpack or object {_init = {"_name", "_info", "_namespace"}}

-- get name
function xpack:name()
    return self._name
end

-- get namespace
function xpack:namespace()
    return self._namespace
end

-- get fullname
function xpack:fullname()
    local namespace = self:namespace()
    return namespace and namespace .. "::" .. self:name() or self:name()
end

-- get values
function xpack:get(name)
    if self._info then
        return self._info:get(name)
    end
end

-- set values
function xpack:set(name, ...)
    if self._info then
        self._info:apival_set(name, ...)
    end
end

-- add values
function xpack:add(name, ...)
    if self._info then
        self._info:apival_add(name, ...)
    end
end

-- get the extra configuration
function xpack:extraconf(name, item, key)
    if self._info then
        return self._info:extraconf(name, item, key)
    end
end

-- get the package license
function xpack:license()
    return self:get("license")
end

-- get the package title
function xpack:title()
    local title = self:get("title")
    if title == nil then
        title = self:name()
    end
    return filter.handle(title, self)
end

-- get the package description
function xpack:description()
    return self:get("description")
end

-- get the platform of package
function xpack:plat()
    return config.get("plat") or os.subhost()
end

-- get the architecture of package
function xpack:arch()
    return config.get("arch") or os.subarch()
end

-- the current platform is belong to the given platforms?
function xpack:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.pack(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current architecture is belong to the given architectures?
function xpack:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.pack(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get xxx_script
function xpack:script(name, generic)
    local script = self:get(name)
    local result = select_script(script, {plat = self:plat(), arch = self:arch()}) or generic
    return result
end

-- get targets
function xpack:targets()
    local targets = self._targets
    if not targets then
        targets = {}
        local targetnames = self:get("targets")
        if targetnames then
            for _, name in ipairs(targetnames) do
                local target = project.target(name, {namespace = self:namespace()})
                if target then
                    table.insert(targets, target)
                else
                    raise("xpack(%s): target(%s) not found!", self:name(), name)
                end
            end
        end
        self._targets = targets
    end
    return targets
end

-- get the given target
function xpack:target(name)
    local targetnames = self:get("targets")
    if targetnames and table.contains(table.wrap(targetnames), name) then
        return project.target(name, {namespace = self:namespace()})
    end
end

-- get formats
function xpack:formats()
    local formats = self._formats
    if not formats then
        formats = hashset.new()
        for _, format in ipairs(self:get("formats")) do
            formats:insert(format)
        end
        self._formats = formats
    end
    return formats
end

-- has the given format?
function xpack:format_has(...)
    local formats = self:formats()
    for _, v in ipairs(table.pack(...)) do
        if v and formats:has(v) then
            return true
        end
    end
end

-- set the current format
function xpack:format_set(format)
    self._FORMAT = format
end

-- get the current format
function xpack:format()
    return self._FORMAT
end

-- get the input kind
function xpack:inputkind()
    local inputkind = self:get("inputkind")
    if inputkind == nil then
        local inputkinds = {
            wix      = "binary",
            nsis     = "binary",
            zip      = "binary",
            targz    = "binary",
            srczip   = "source",
            srctargz = "source",
            runself  = "source",
            deb      = "source",
            srpm     = "source",
            rpm      = "source"
        }
        inputkind = inputkinds[self:format()] or "binary"
    end
    return inputkind
end

-- get the output kind
function xpack:outputkind()
    local outputkinds = {
        wix      = "binary",
        nsis     = "binary",
        zip      = "binary",
        targz    = "binary",
        srczip   = "source",
        srctargz = "source",
        runself  = "source",
        deb      = "binary",
        srpm     = "source",
        rpm      = "binary"
    }
    local outputkind = outputkinds[self:format()] or "binary"
    return outputkind
end

-- pack from source files?
function xpack:from_source()
    return self:inputkind() == "source"
end

-- pack from binary files?
function xpack:from_binary()
    return self:inputkind() == "binary"
end

-- pack with source files?
function xpack:with_source()
    return self:outputkind() == "source"
end

-- pack with binary files?
function xpack:with_binary()
    return self:outputkind() == "binary"
end

-- get the build directory
function xpack:buildir()
    return path.join(config.buildir(), ".xpack", self:name())
end

-- get the output directory
function xpack:outputdir()
    local outputdir = option.get("outputdir")
    if outputdir == nil then
        outputdir = path.join(config.buildir(), "xpack", self:name())
    end
    return outputdir
end

-- get the basename
function xpack:basename()
    local basename = option.get("basename") or self:get("basename")
    if basename == nil then
        basename = self:name()
        if self:with_source() then
            basename = basename .. "-src"
        end
        local version = self:version()
        if version then
            basename = basename .. "-" .. version
        end
    end
    -- we need filter builtin variables, e.g. $(plat), $(arch), $(version) ...
    return filter.handle(basename, self)
end

-- get the spec variables
function xpack:specvars()
    local specvars = self._specvars
    if specvars == nil then
        specvars = {
            PACKAGE_ARCH        = self:arch(),
            PACKAGE_PLAT        = self:plat(),
            PACKAGE_NAME        = self:name(),
            PACKAGE_TITLE       = self:title() or "",
            PACKAGE_DESCRIPTION = self:description() or "",
            PACKAGE_FILENAME    = self:filename(),
            PACKAGE_AUTHOR      = self:get("author") or "",
            PACKAGE_MAINTAINER  = self:get("maintainer") or self:get("author") or "",
            PACKAGE_HOMEPAGE    = self:get("homepage") or "",
            PACKAGE_COPYRIGHT   = self:get("copyright") or "",
            PACKAGE_COMPANY     = self:get("company") or "",
            PACKAGE_ICONFILE    = self:get("iconfile") or "",
            PACKAGE_LICENSE     = self:license() or "",
            PACKAGE_LICENSEFILE = self:get("licensefile") or ""
        }

        -- get version
        local version, version_build = self:version()
        if version then
            specvars.PACKAGE_VERSION = version or "0.0.0"
            try {function ()
                local v = semver.new(version)
                if v then
                    specvars.PACKAGE_VERSION_MAJOR = v:major() or "0"
                    specvars.PACKAGE_VERSION_MINOR = v:minor() or "0"
                    specvars.PACKAGE_VERSION_ALTER = v:patch() or "0"
                end
            end}
            specvars.PACKAGE_VERSION_BUILD = version_build or ""
        end

        -- get git information
        local cmds =
        {
            GIT_TAG         = {"describe", "--tags"},
            GIT_TAG_LONG    = {"describe", "--tags", "--long"},
            GIT_BRANCH      = {"rev-parse", "--abbrev-ref", "HEAD"},
            GIT_COMMIT      = {"rev-parse", "--short", "HEAD"},
            GIT_COMMIT_LONG = {"rev-parse", "HEAD"},
            GIT_COMMIT_DATE = {"log", "-1", "--date=format:%Y%m%d%H%M%S", "--format=%ad"}
        }
        for name, argv in pairs(cmds) do
            specvars[name] = function ()
                local result
                local git = find_tool("git")
                if git then
                    result = try {function ()
                        return os.iorunv(git.program, argv)
                    end}
                end
                if not result then
                    result = "none"
                end
                return result:trim()
            end
        end

        -- get user variables
        local vars = self:get("specvar")
        if vars then
            table.join2(specvars, vars)
        end
        self._specvars = specvars
    end
    return specvars
end

-- get the extension
function xpack:extension()
    local extension = self:get("extension")
    if extension == nil then
        local extensions = {
            wix      = ".msi",
            nsis     = ".exe",
            zip      = ".zip",
            targz    = ".tar.gz",
            srczip   = ".zip",
            srctargz = ".tar.gz",
            runself  = ".gz.run",
            deb      = ".deb",
            srpm     = ".src.rpm",
            rpm      = ".rpm"
        }
        extension = extensions[self:format()] or ""
    end
    return extension
end

-- get the output filename
function xpack:filename()
    return self:basename() .. self:extension()
end

-- get the output file
function xpack:outputfile()
    return path.join(self:outputdir(), self:filename())
end

-- get the package version
function xpack:version()
    local version = self:get("version")
    local version_build
    if version == nil then
        for _, target in ipairs(self:targets()) do
            version, version_build = target:version()
            if version then
                break
            end
        end
        if version == nil then
            version, version_build = project.version()
        end
    else
        version_build = self:extraconf("version", version, "build")
        if type(version_build) == "string" then
            version_build = os.date(version_build, os.time())
        end
    end
    return version, version_build
end

-- get the install files
function xpack:installfiles()
    return match_copyfiles(self, "installfiles", self:installdir())
end

-- get the installed root directory, this is just a temporary sandbox installation path,
-- we may replace it with the actual installation path in the specfile
function xpack:install_rootdir()
    return path.join(self:buildir(), "installed", self:format())
end

-- get the installed directory
function xpack:installdir(...)
    local installdir = self:install_rootdir()
    local prefixdir = self:prefixdir()
    if prefixdir then
        installdir = path.join(installdir, prefixdir)
    end
    return path.normalize(path.join(installdir, ...))
end

-- get the source files
function xpack:sourcefiles()
    return match_copyfiles(self, "sourcefiles", self:sourcedir())
end

-- get the source root directory
function xpack:source_rootdir()
    return path.join(self:buildir(), "source", self:format())
end

-- get the source directory
function xpack:sourcedir(...)
    local sourcedir = self:source_rootdir()
    local prefixdir = self:prefixdir()
    if prefixdir then
        sourcedir = path.join(sourcedir, prefixdir)
    end
    return path.normalize(path.join(sourcedir, ...))
end

-- get the prefixdir
function xpack:prefixdir()
    local prefixdir = self:get("prefixdir")
    if prefixdir then
        return filter.handle(prefixdir, self)
    end
    return prefixdir
end

-- get the binary directory
function xpack:bindir()
    local bindir = self:get("bindir") or self:extraconf("prefixdir", self:prefixdir(), "bindir")
    if bindir == nil then
        bindir = "bin"
    end
    return self:installdir(bindir)
end

-- get the library directory
function xpack:libdir()
    local libdir = self:get("libdir") or self:extraconf("prefixdir", self:prefixdir(), "libdir")
    if libdir == nil then
        libdir = "lib"
    end
    return self:installdir(libdir)
end

-- get the include directory
function xpack:includedir()
    local includedir = self:get("includedir") or self:extraconf("prefixdir", self:prefixdir(), "includedir")
    if includedir == nil then
        includedir = "include"
    end
    return self:installdir(includedir)
end

-- get the components
function xpack:components()
    local components = _g.components
    if components == nil then
        components = {}
        local xpack_component_scope = project.scope("xpack_component")
        for _, component_name in ipairs(self:get("components")) do
            local scope = xpack_component_scope[component_name]
            if scope then
                local instance = xpack_component.new(component_name, scope, self)
                components[component_name] = instance
            else
                raise("unknown xpack component(%s) in xpack(%s)", component_name, self:name())
            end
        end
        _g.components = components
    end
    return components
end

-- get the given component
function xpack:component(name)
    return self:components()[name]
end

-- new a xpack, and we need to clone scope info,
-- because two different format packages maybe have same scope
function _new(name, info)
    local parts = name:split("::", {plain = true})
    name = parts[#parts]
    table.remove(parts)
    local namespace
    if #parts > 0 then
        namespace = table.concat(parts, "::")
    end
    return xpack {name, info:clone(), namespace}
end

-- get xpack packages
function packages()
    local packages = _g.packages
    if not packages then
        packages = {}
        local packages_need = option.get("packages")
        if packages_need then
            packages_need = hashset.from(packages_need)
        end
        local xpack_scope = project.scope("xpack")
        for name, scope in pairs(xpack_scope) do
            local need = false
            if packages_need then
                if packages_need:has(name) then
                    need = true
                end
            else
                need = true
            end
            if need then
                local formats = scope:get("formats")
                if formats then
                    for _, format in ipairs(formats) do
                        local instance = _new(name, scope)
                        instance:format_set(format)
                        table.insert(packages, instance)
                    end
                else
                    raise("xpack(%s): formats not found, please use `set_formats()` to set it.", scope:get("name"))
                end
            end
        end
        _g.packages = packages
    end
    return packages
end
