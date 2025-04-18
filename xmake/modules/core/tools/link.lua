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
-- @file        link.lua
--

-- imports
import("core.project.config")
import("private.tools.vstool")

-- init it
function init(self)

    -- init ldflags
    self:set("ldflags", "-nologo", "-dynamicbase", "-nxcompat")

    -- init arflags
    self:set("arflags", "-nologo")

    -- init shflags
    self:set("shflags", "-nologo")

    -- init flags map
    self:set("mapflags",
    {
        -- strip
        ["-s"]                  = ""
    ,   ["-S"]                  = ""

        -- others
    ,   ["-ftrapv"]             = ""
    ,   ["-fsanitize=address"]  = ""
    })
end

-- get the property
function get(self, name)
    local values = self._INFO[name]
    if name == "ldflags" or name == "arflags" or name == "shflags" then
        -- switch architecture, @note does cache it in init() for generating vs201x project
        values = table.join(values, "-machine:" .. (self:arch() or "x86"))
    end
    return values
end

-- make the strip flag
function nf_strip(self, level, opt)

    -- link.exe/arm64 does not support /opt:ref, /opt:icf
    local target = opt.target
    if target and target:is_arch("arm64") then
        return
    end

    -- @note we explicitly strip some useless code, because `/debug` may keep them
    -- @see https://github.com/xmake-io/xmake/issues/907
    if level == "all" then
        -- we enable /ltcg for optimize/smallest:/Gl
        local flags = {"/opt:ref", "/opt:icf"}
        if target and target:get("optimize") == "smallest" then
            table.insert(flags, "/ltcg")
        end
        return flags
    elseif level == "debug" then
        return {"/opt:ref", "/opt:icf"}
    end
end

-- make the symbol flag
function nf_symbol(self, level, opt)

    -- debug? generate *.pdb file
    local flags = nil
    local target = opt.target
    if target then
        if target:type() == "target" then
            if level == "debug" and (target:is_binary() or target:is_shared()) then
                flags = {"-debug", "-pdb:" .. target:symbolfile()}
            end
        else -- for option
            if level == "debug" then
                flags = "-debug"
            end
        end
    end
    return flags
end

-- make the link flag
function nf_link(self, lib)
    if not lib:endswith(".lib") and not lib:endswith(".obj") then
        lib = lib .. ".lib"
    end
    return lib
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the runtime flag
function nf_runtime(self, runtime)
    if runtime and runtime:startswith("MT") then
        return "-nodefaultlib:msvcrt.lib"
    end
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return {"-libpath:" .. path.translate(dir)}
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}
    local argv = table.join(flags, "-out:" .. targetfile, objectfiles)
    if not opt.rawargs then
        argv = winos.cmdargv(argv)
    end
    -- @note we cannot put -lib/-dll to @args.txt
    if targetkind == "static" then
        table.insert(argv, 1, "-lib")
    elseif targetkind == "shared" then
        table.insert(argv, 1, "-dll")
        if opt.target then
            table.insert(argv, "/IMPLIB:" .. path.join(opt.target:implibdir(), path.basename(targetfile) .. ".lib"))
        end
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags, opt)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- ensure the implib directory
    if opt and opt.target and opt.target:implibdir() then
        os.mkdir(opt.target:implibdir())
    end

    try
    {
        function ()

            local toolchain = self:toolchain()
            local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
            if toolchain and toolchain:name() == "masm32" then
                os.iorunv(program, argv, {envs = self:runenvs()})
            else
                -- use vstool to link and enable vs_unicode_output @see https://github.com/xmake-io/xmake/issues/528
                vstool.runv(program, argv, {envs = self:runenvs()})
            end
        end,
        catch
        {
            function (errors)

                -- use link/stdout as errors first from vstool.iorunv()
                if type(errors) == "table" then
                    local errs = errors.stdout or ""
                    if #errs:trim() == 0 then
                        errs = errors.stderr or ""
                    end
                    errors = errs
                end
                os.raise(tostring(errors))
            end
        }
    }
end

