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
import("core.base.json")
import("core.base.option")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")

-- get conda prefix directory
function _conda_prefixdir(conda)
    local prefixdir = _g.prefixdir
    if prefixdir == nil then
        prefixdir = os.getenv("CONDA_PREFIX")
        if not prefixdir then
            local info = try {function () return os.iorunv(conda.program, {"info"}) end}
            if info then
                for _, line in ipairs(info:split('\n', {plain = true})) do
                    if line:find("base environment") then
                        prefixdir = line:match("ase environment : (.-) %(writable%)")
                        if prefixdir then
                            prefixdir = prefixdir:trim()
                        end
                        break
                    end
                end
            end
        end
        _g.prefixdir = prefixdir
    end
    return prefixdir
end

-- find package using the conda package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.12.0")
--
function main(name, opt)

    -- check
    opt = opt or {}
    if not is_host(opt.plat) or os.arch() ~= opt.arch then
        return
    end

    -- find conda
    local conda = find_tool("conda")
    if not conda then
        return
    end

    -- find package
    local version, build
    local listinfo = try {function () return os.iorunv(conda.program, {"list", name}) end}
    if listinfo then
        for _, line in ipairs(listinfo:split('\n', {plain = true})) do
            if line:startswith(name) then
                version, build = listinfo:match(name .. "%s-([%w%.%d%-%+]+)%s-([%w%d_]+)")
                if version and build then
                    break
                end
            end
        end
    end
    if not version or not build then
        return
    end
    if opt.require_version and opt.require_version:find('.', 1, true) and opt.require_version ~= version then
        return
    end

    -- get meta info of package
    -- e.g. ~/miniconda2/conda-meta/libpng-1.6.37-ha441bb4_0.json
    local prefixdir = _conda_prefixdir(conda)
    if not prefixdir then
        return
    end
    local metafile = path.join(prefixdir, "conda-meta", name .. "-" .. version .. "-" .. build .. ".json")
    if not os.isfile(metafile) then
        return
    end
    local metainfo = json.loadfile(metafile)
    if not metainfo or not metainfo.extracted_package_dir then
        return
    end

    -- save includedirs, linkdirs and links
    local result = nil
    local packagedir = metainfo.extracted_package_dir
    for _, line in ipairs(metainfo.files) do
        line = line:trim()

        -- get includedirs
        local pos = line:find("include/", 1, true)
        if pos then
            result = result or {}
            result.includedirs = result.includedirs or {}
            table.insert(result.includedirs, path.join(packagedir, line:sub(1, pos + 7)))
        end

        -- get linkdirs and links
        if line:endswith(".lib") or line:endswith(".a") or line:endswith(".so") or line:endswith(".dylib") then
            result = result or {}
            result.links = result.links or {}
            result.linkdirs = result.linkdirs or {}
            result.libfiles = result.libfiles or {}
            table.insert(result.linkdirs, path.join(packagedir, path.directory(line)))
            table.insert(result.links, target.linkname(path.filename(line), {plat = opt.plat}))
            table.insert(result.libfiles, path.join(packagedir, path.directory(line), path.filename(line)))
        end

        -- add shared library directory (/bin/) to linkdirs for running with PATH on windows
        if opt.plat == "windows" and line:endswith(".dll") then
            result = result or {}
            result.linkdirs = result.linkdirs or {}
            result.libfiles = result.libfiles or {}
            table.insert(result.linkdirs, path.join(packagedir, path.directory(line)))
            table.insert(result.libfiles, path.join(packagedir, path.directory(line), path.filename(line)))
        end
    end

    -- save version
    if result then
        result.version = metainfo.version or version
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
    return result
end
