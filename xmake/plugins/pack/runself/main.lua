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
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import(".batchcmds")

-- get the makeself
function _get_makeself()

    -- enter the environments of makeself
    local oldenvs = packagenv.enter("makeself")

    -- find makeself
    local packages = {}
    local makeself = find_tool("makeself.sh")
    if not makeself then
        table.join2(packages, install_packages("makeself"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not makeself then
        makeself = find_tool("makeself.sh", {force = true})
    end
    assert(makeself, "makeself not found!")
    return makeself, oldenvs
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    return specvars
end

-- write install command
function _write_installcmd(package, scriptfile, cmd)
    local opt = cmd.opt or {}
    local kind = cmd.kind
    if kind == "cp" then
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = cmd.dstpath
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            scriptfile:print("cp -p \"%s\" \"%s\"", srcfile, dstfile)
        end
    elseif kind == "rm" then
        local filepath = cmd.filepath
        scriptfile:print("rm -f \"%s\"", filepath)
    elseif kind == "rmdir" then
        local dir = cmd.dir
        scriptfile:print("rm -rf \"%s\"", dir)
    elseif kind == "mv" then
        local srcpath = cmd.srcpath
        local dstpath = cmd.dstpath
        scriptfile:print("mv \"%s\" \"%s\"", srcfile, dstfile)
    elseif kind == "cd" then
        local dir = cmd.dir
        scriptfile:print("cd \"%s\"", dir)
    elseif kind == "mkdir" then
        local dir = cmd.dir
        scriptfile:print("mkdir -p \"%s\"", dir)
    elseif cmd.program then
        scriptfile:print("%s", os.args(table.join(cmd.program, cmd.argv)))
    end
end

-- write install commands
function _write_installcmds(package, scriptfile, cmds)
    for _, cmd in ipairs(cmds) do
        _write_installcmd(package, scriptfile, cmd)
    end
end

-- pack runself package
function _pack_runself(makeself, package)

    -- install the initial specfile
    local specfile = path.join(package:buildir(), package:basename() .. ".lsm")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "runself", "makeself.lsm")
        os.cp(specfile_template, specfile, {writeable = true})
    end

    -- replace variables in specfile
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    local specvars_names = {}
    local specvars_values = {}
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        table.insert(specvars_names, name)
    end)
    for _, name in ipairs(specvars_names) do
        name = name:trim()
        if specvars_values[name] == nil then
            local value = specvars[name]
            if type(value) == "function" then
                value = value()
            end
            if value ~= nil then
                dprint("  > replace %s -> %s", name, value)
            end
            if type(value) == "table" then
                dprint("invalid variable value", value)
            end
            specvars_values[name] = value
        end
    end
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        name = name:trim()
        return specvars_values[name]
    end)

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

    -- generate the setup.sh script
    local sourcedir = package:sourcedir()
    local setupfile = path.join(sourcedir, "__setup__.sh")
    os.cp(path.join(os.programdir(), "scripts", "xpack", "runself", "setup.sh"), setupfile)
    local scriptfile = io.open(setupfile, "a+")
    if scriptfile then
        _write_installcmds(package, scriptfile, batchcmds.get_installcmds(package):cmds())
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                _write_installcmds(package, scriptfile, batchcmds.get_installcmds(component):cmds())
            end
        end
        scriptfile:close()
    end

    -- make package
    os.vrunv(makeself, {"--gzip", "--sha256", "--lsm", specfile,
        sourcedir, package:outputfile(), package:basename(), "./__setup__.sh"})
end

function main(package)

    if is_subhost("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get makeself
    local makeself, oldenvs = _get_makeself()

    -- pack runself package
    _pack_runself(makeself.program, package)

    -- done
    os.setenvs(oldenvs)
end
