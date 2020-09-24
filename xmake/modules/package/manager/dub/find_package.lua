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
import("core.base.option")
import("core.base.semver")
import("core.base.json")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")
import("lib.detect.find_file")

-- find package using the dub package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- find dub
    local dub = find_tool("dub")
    if not dub then
        raise("dub not found!")
    end

    -- get the library pattern
    local libpattern = (opt.plat == "windows") and "*.lib" or "*.a"

    -- find package
    local result
    local pkglist = os.iorunv(dub.program, {"list"})
    if pkglist then
        local pkgdir
        for _, line in ipairs(pkglist:split('\n', {plain = true})) do
            local pkginfo = line:split(':', {plain = true})
            if #pkginfo == 2 then
                local pkgkey  = pkginfo[1]:trim():split(' ', {plain = true})
                local pkgpath = pkginfo[2]:trim()
                if #pkgkey == 2 then
                    local pkgname    = pkgkey[1]:trim()
                    local pkgversion = pkgkey[2]:trim()
                    if pkgname == name and find_file(libpattern, pkgpath) and
                        (not opt.version or opt.version == "latest" or opt.version == "master" or semver.satisfies(pkgversion, opt.version)) then
                        pkgdir = pkgpath
                        break
                    end
                end
            end
        end
        if pkgdir then
            local links = {}
            for _, libraryfile in ipairs(os.files(path.join(pkgdir, libpattern))) do
                table.insert(links, target.linkname(path.filename(libraryfile)))
            end
            local includedirs = {}
            local dubjson = path.join(pkgdir, "dub.json")
            if os.isfile(dubjson) then
                dubjson = json.loadfile(dubjson)
                if dubjson and dubjson.importPaths then
                    for _, importPath in ipairs(dubjson.importPaths) do
                        table.insert(includedirs, path.join(pkgdir, importPath))
                    end
                end
            end
            if #includedirs > 0 and #links > 0 then
                result = {version = opt.version, links = links, linkdirs = pkgdir, includedirs = includedirs}
            end
        end
    end
    return result
end
