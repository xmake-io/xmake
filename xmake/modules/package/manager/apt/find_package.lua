
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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")


-- fetch_pkg_info fetch package info using the dpkg package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.0")
-- @param dpkg_program  the dpkg program
--
function fetch_pkg_info(name, opt, dpkg_program)
    -- find package
    local result = nil
    local is_found_includedirs = false
    local listinfo = try {function () return os.iorunv(dpkg_program, {"--listfiles", name}) end}
    if listinfo then
        result = {}
        for _, line in ipairs(listinfo:split('\n', {plain = true})) do
            line = line:trim()

            -- get includedirs
            local pos = line:find("include/", 1, true)
            if pos then
                -- we need not add includedirs, gcc/clang will use /usr/ as default sysroot
                result = result or {}
                is_found_includedirs = true
            end

            -- get linkdirs and links
            if line:endswith(".a") or line:endswith(".so") then
                result = result or {}
                result.links = result.links or {}
                result.linkdirs = result.linkdirs or {}
                result.libfiles = result.libfiles or {}
                table.insert(result.linkdirs, path.directory(line))
                table.insert(result.links, target.linkname(path.filename(line), {plat = opt.plat}))
                table.insert(result.libfiles, path.join(path.directory(line), path.filename(line)))
            end
        end
    end

    -- remove repeat
    if result then
        if result.links then
            result.links = table.unique(result.links)
        end
        if result.linkdirs then
            result.linkdirs = table.unique(result.linkdirs)
        end
        if result.includedirs then
            result.includedirs = table.unique(result.includedirs)
        end
    end
    return result, is_found_includedirs
end


-- find package using the dpkg package manager, support alias deb
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.0")
--
function main(name, opt)
    -- check
    opt = opt or {}
    if not is_host(opt.plat) or os.arch() ~= opt.arch then
        return
    end

    -- find dpkg
    local dpkg = find_tool("dpkg")
    if not dpkg then
        return
    end

    local pkg_info = nil
    local is_found_includedirs = nil
    pkg_info, is_found_includedirs = fetch_pkg_info(name, opt, dpkg.program)

    -- not include or libinfo
    if (type(pkg_info) == "table" and #pkg_info == 0 and not is_found_includedirs) then
        -- fetch the only depends pkg
        local status_info = try {function () return os.iorunv(dpkg.program, {"--status", name}) end}
        if not status_info then
            return
        end

        local depends_str = nil
        _, _, depends_str = string.find(status_info, "Depends%s*:%s*(.-)\n")
        if depends_str and not depends_str:find(",", 1, true) then
            depends_str = depends_str:trim()
            depends_str, _ = string.gsub(depends_str, "%(.*%)", "")
            local depends_pkg_name = depends_str:trim()
            pkg_info, _ = fetch_pkg_info(depends_pkg_name, opt, dpkg.program)
        end

    end

    return pkg_info
end
