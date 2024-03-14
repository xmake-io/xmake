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
-- @file        xpack_component.lua
--

-- imports
import("core.base.object")
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("private.core.base.select_script")
import("private.core.base.match_copyfiles")

-- define module
local xpack_component = xpack_component or object {_init = {"_name", "_info", "_package"}}

-- get name
function xpack_component:name()
    return self._name
end

-- get values
function xpack_component:get(name)
    if self._info then
        return self._info:get(name)
    end
end

-- set values
function xpack_component:set(name, ...)
    if self._info then
        self._info:apival_set(name, ...)
    end
end

-- add values
function xpack_component:add(name, ...)
    if self._info then
        self._info:apival_add(name, ...)
    end
end

-- get the extra configuration
function xpack_component:extraconf(name, item, key)
    if self._info then
        return self._info:extraconf(name, item, key)
    end
end

-- get the component title
function xpack_component:title()
    return self:get("title") or self:name()
end

-- get the component description
function xpack_component:description()
    return self:get("description")
end

-- get xxx_script
function xpack_component:script(name, generic)
    local script = self:get(name)
    local result = select_script(script, {plat = self:package():plat(), arch = self:package():arch()}) or generic
    return result
end

-- get targets
function xpack_component:targets()
    local targets = self._targets
    if not targets then
        targets = {}
        local targetnames = self:get("targets")
        if targetnames then
            for _, name in ipairs(targetnames) do
                local target = project.target(name)
                if target then
                    table.insert(targets, target)
                else
                    raise("xpack_component(%s): target(%s) not found!", self:name(), name)
                end
            end
        end
        self._targets = targets
    end
    return targets
end

-- get the given target
function xpack_component:target(name)
    local targetnames = self:get("targets")
    if targetnames and table.contains(table.wrap(targetnames), name) then
        return project.target(name)
    end
end

-- get the package
function xpack_component:package()
    return self._package
end

-- get the install files
function xpack_component:installfiles()
    return match_copyfiles(self, "installfiles", self:package():installdir())
end

-- get the installed root directory, this is just a temporary sandbox installation path,
-- we may replace it with the actual installation path in the specfile
function xpack_component:install_rootdir()
    return self:package():install_rootdir()
end

-- get the installed directory
function xpack_component:installdir(...)
    return self:package():installdir(...)
end

-- get the source files
function xpack_component:sourcefiles()
    return match_copyfiles(self, "sourcefiles", self:package():sourcedir())
end

-- get the source root directory
function xpack_component:source_rootdir()
    return self:package():souece_rootdir()
end

-- get the source directory
function xpack_component:sourcedir(...)
    return self:package():sourcedir(...)
end

-- get the binary directory
function xpack_component:bindir()
    return self:package():bindir()
end

-- get the library directory
function xpack_component:libdir()
    return self:package():libdir()
end

-- get the include directory
function xpack_component:includedir()
    return self:package():includedir()
end

-- pack from source files?
function xpack_component:from_source()
    return self:package():from_source()
end

-- pack from binary files?
function xpack_component:from_binary()
    return self:package():from_binary()
end

-- new a xpack_component
function new(name, info, package)
    return xpack_component {name, info:clone(), package}
end

