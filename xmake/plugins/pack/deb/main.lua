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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("utils.archive")
import(".batchcmds")

-- get the debuild
function _get_debuild()
    local debuild = find_tool("debuild", {force = true})
    assert(debuild, "debuild not found!")
    return debuild
end

-- get archive file
function _get_archivefile(package)
    return path.absolute(path.join(package:buildir(), package:name() .. "_" .. package:version() .. ".orig.tar.gz"))
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    return specvars
end

-- pack deb package
function _pack_deb(debuild, package)
    local buildir = package:buildir()
    local workdir = path.join(buildir, "working")

    -- install the initial debian directory
    local debiandir = path.join(workdir, "debian")
    if not os.isdir(debiandir) then
        local debiandir_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "deb", "debian")
        os.cp(debiandir_template, debiandir)
    end

    -- replace variables in specfile
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    for _, specfile in ipairs(os.files(path.join(debiandir, "**"))) do
        io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
            name = name:trim()
            local value = specvars[name]
            if type(value) == "function" then
                value = value()
            end
            if value ~= nil then
                dprint("[%s]:  > replace %s -> %s", path.filename(specfile), name, value)
            end
            if type(value) == "table" then
                dprint("invalid variable value", value)
            end
            return value
        end)
    end

    -- archive source files
    local srcfiles, dstfiles = package:sourcefiles()
    for idx, srcfile in ipairs(srcfiles) do
        os.vcp(srcfile, dstfiles[idx])
    end
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            local srcfiles, dstfiles = component:sourcefiles()
            for idx, srcfile in ipairs(srcfiles) do
                os.vcp(srcfile, dstfiles[idx])
            end
        end
    end

    -- archive install files
    local rootdir = package:source_rootdir()
    local oldir = os.cd(rootdir)
    local archivefiles = os.files("**")
    os.cd(oldir)
    local archivefile = _get_archivefile(package)
    os.tryrm(archivefile)
    archive.archive(archivefile, archivefiles, {curdir = rootdir, compress = "best"})

    -- build package, TODO modify key
    os.vrunv(debuild, {"-S", "-k02713554FA2CE4AADA20AB23167A22F22C0C68C9"}, {curdir = workdir})
end

function main(package)
    if not is_host("linux") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get debuild
    local debuild = _get_debuild()

    -- pack deb package
    _pack_deb(debuild.program, package)
end
