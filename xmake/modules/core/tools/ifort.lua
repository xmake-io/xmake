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
-- @file        ifort.lua
--

if is_host("windows") then

    -- imports
    inherit("cl")
    inherit("link")
    import("private.tools.vstool")

    -- init it
    function init(self)
        self:set("fcflags", "-nologo")
        self:set("fcldflags", "-nologo", "-dynamicbase", "-nxcompat")
        self:set("fcshflags", "-nologo")
    end

    -- get the property
    function get(self, name)
        local values = self._INFO[name]
        if name == "fcldflags" or name == "fcarflags" or name == "fcshflags" then
            -- switch architecture, @note does cache it in init() for generating vs201x project
            values = table.join(values, "-machine:" .. (self:arch() or "x86"))
        end
        return values
    end

    -- make the link arguments list
    function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
        opt = opt or {}
        local argv = table.join("-o", targetfile, objectfiles, "/link", flags)
        if not opt.rawargs then
            argv = winos.cmdargv(argv, {escape = true})
        end
        -- @note we cannot put -dll to @args.txt
        if targetkind == "shared" then
            table.insert(argv, 1, "-dll")
        end
        return self:program(), argv
    end

    -- link the target file
    function link(self, objectfiles, targetkind, targetfile, flags, opt)

        -- ensure the target directory
        os.mkdir(path.directory(targetfile))

        try
        {
            function ()

                -- use vstool to link and enable vs_unicode_output @see https://github.com/xmake-io/xmake/issues/528
                local program, argv = linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
                vstool.runv(program, argv, {envs = self:runenvs()})
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
else
    inherit("gfortran")
end
