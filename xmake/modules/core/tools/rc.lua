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
-- @file        rc.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("private.tools.vstool")

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    else
        return deps
    end
end

-- parse include file
function _parse_includefile(line)
    if line:startswith("#line") then
        return line:match("#line %d+ \"(.+)\"")
    elseif line:find("ICON", 1, true) and line:find(".ico", 1, true) then
        -- 101 ICON "xxx.ico"
        return line:match("ICON%s+\"(.+.ico)\"")
    elseif line:find("BITMAP", 1, true) and line:find(".bmp", 1, true) then
        return line:match("BITMAP%s+\"(.+.bmp)\"")
    end
end

-- init it
function init(self)
    if self:has_flags("-nologo", "mrcflags") then
        -- fix vs2008 on xp, e.g. fatal error RC1106: invalid option: -ologo
        self:set("mrcflags", "-nologo")
    end
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return {"-I" .. dir}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join(flags, "-Fo" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    try
    {
        function ()
            -- @note we need not uses vstool.iorunv to enable unicode output for rc.exe
            local program, argv = compargv(self, sourcefile, objectfile, flags)
            local outdata, errdata = os.iorunv(program, argv, {envs = self:runenvs()})
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)
                -- use stdout as errors first from vstool.iorunv()
                if type(errors) == "table" then
                    local errs = errors.stdout or ""
                    if #errs:trim() == 0 then
                        errs = errors.stderr or ""
                    end
                    errors = errs
                end
                os.raise(tostring(errors))
            end
        },
        finally
        {
            function (ok, warnings)
                if warnings and #warnings > 0 and option.get("verbose") then
                    cprint("${color.warning}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }

    -- try to use cl.exe to parse includes, but cl.exe maybe not exists in masm32 sdk
    -- @see https://github.com/xmake-io/xmake/issues/2562
    local cl = self:toolchain():tool("cxx")
    if cl then
        local outfile = os.tmpfile() .. ".rc.out"
        local errfile = os.tmpfile() .. ".rc.err"
        local ok = try {function () os.execv(cl, {"-E", sourcefile}, {stdout = outfile, stderr = errfile, envs = self:runenvs()}); return true end}
        if ok and os.isfile(outfile) then
            local depfiles_rc
            local includeset = hashset.new()
            local file = io.open(outfile)
            local projectdir = os.projectdir()
            for line in file:lines() do
                local includefile = _parse_includefile(line)
                if includefile then
                    includefile = _normailize_dep(includefile, projectdir)
                    if includefile and not includeset:has(includefile)
                        and path.absolute(includefile) ~= path.absolute(sourcefile)
                        and os.isfile(includefile) then
                        depfiles_rc = (depfiles_rc or "") .. "\n" .. includefile
                        includeset:insert(includefile)
                    end
                end
            end
            file:close()
            if dependinfo then
                dependinfo.depfiles_rc = depfiles_rc
            end
        end
        os.tryrm(outfile)
        os.tryrm(errfile)
    end
end

