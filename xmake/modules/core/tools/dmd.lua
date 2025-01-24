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
-- @file        dmd.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- init it
function init(self)

    -- init arflags
    self:set("dcarflags", "-lib")

    -- init shflags
    self:set("dcshflags", "-shared")

    -- add -fPIC for shared
    if not self:is_plat("windows", "mingw") then
        self:add("dcshflags", "-fPIC")
        self:add("shared.dcflags", "-fPIC")
    end
end

-- make the optimize flag
function nf_optimize(self, level)
    -- only for source kind
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps =
        {
            fast        = "-O"
        ,   faster      = {"-O", "-release"}
        ,   fastest     = {"-O", "-release", "-inline", "-boundscheck=off"}
        ,   smallest    = {"-O", "-release", "-boundscheck=off"}
        ,   aggressive  = {"-O", "-release", "-inline", "-boundscheck=off"}
        }
        return maps[level]
    end
end

-- make the strip flag
function nf_strip(self, level)
    if not self:is_plat("windows") then
        local maps = {
            debug = "-L-S",
            all   = "-L-s"
        }
        if self:is_plat("macosx", "iphoneos") then
            maps.all = {"-L-x", "-L-dead_strip"}
        end
        return maps[level]
    end
end

-- make the symbol flag
function nf_symbol(self, level)
    local kind = self:kind()
    if language.sourcekinds()[kind] then
        local maps = _g.symbol_maps
        if not maps then
            maps = {
                debug  = {"-g", "-debug"}
            }
            _g.symbol_maps = maps
        end
        return maps[level .. '_' .. kind] or maps[level]
    elseif (kind == "dcld" or kind == "dcsh") and self:is_plat("windows") and level == "debug" then
        return "-g"
    end
end

-- make the warning flag
function nf_warning(self, level)
    local maps = {
        none        = "-d",
        less        = "-w",
        more        = "-w -wi",
        all         = "-w -wi",
        everything  = "-w -wi",
        error       = "-de"
    }
    return maps[level]
end

-- make the vector extension flag
function nf_vectorext(self, extension)
    local maps = {
        avx  = "-mcpu=avx",
        avx2 = "-mcpu=avx"
    }
    return maps[extension]
end

-- make the includedir flag
function nf_includedir(self, dir)
    return {"-I" .. dir}
end

-- make the sysincludedir flag
function nf_sysincludedir(self, dir)
    return nf_includedir(self, dir)
end

-- make the link flag
function nf_link(self, lib)
    if self:is_plat("windows") then
        return "-L" .. lib .. ".lib"
    else
        return "-L-l" .. lib
    end
end

-- make the syslink flag
function nf_syslink(self, lib)
    return nf_link(self, lib)
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    if self:is_plat("windows") then
        return {"-L-libpath:" .. dir}
    else
        return {"-L-L" .. dir}
    end
end

-- make the framework flag
function nf_framework(self, framework)
    if self:is_plat("macosx") then
        return {"-L-framework", "-L" .. framework}
    end
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    if self:is_plat("macosx") then
        return {"-L-F" .. path.translate(frameworkdir)}
    end
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    if not self:is_plat("windows") then
        dir = path.translate(dir)
        if self:has_flags("-L-rpath=" .. dir, "ldflags") then
            return {"-L-rpath=" .. (dir:gsub("@[%w_]+", function (name)
                local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
                return maps[name]
            end))}
        elseif self:has_flags("-L-rpath -L" .. dir, "ldflags") then
            return {"-L-rpath", "-L" .. (dir:gsub("%$ORIGIN", "@loader_path"))}
        end
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags, opt)
    opt = opt or {}

    -- add rpath for dylib (macho), e.g. -install_name @rpath/file.dylib
    local flags_extra = {}
    if targetkind == "shared" and self:is_plat("macosx") then
        table.insert(flags_extra, "-L-install_name")
        table.insert(flags_extra, "-L@rpath/" .. path.filename(targetfile))
    end

    -- init arguments
    local argv = table.join(flags, flags_extra, "-of" .. targetfile, objectfiles)
    if is_host("windows") and not opt.rawargs then
        argv = winos.cmdargv(argv, {escape = true})
    end
    return self:program(), argv
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)
    os.mkdir(path.directory(targetfile))
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- make the compile arguments list
function compargv(self, sourcefile, objectfile, flags)
    return self:program(), table.join("-c", flags, "-of" .. objectfile, sourcefile)
end

-- compile the source file
function compile(self, sourcefile, objectfile, dependinfo, flags, opt)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    opt = opt or {}
    local depfile = dependinfo and os.tmpfile() or nil
    try
    {
        function ()

            -- generate includes file
            local compflags = flags
            if depfile then
                compflags = table.join(compflags, "-makedeps=" .. depfile)
            end

            -- do compile
            local program, argv = compargv(self, sourcefile, objectfile, compflags)
            os.iorunv(program, argv, {envs = self:runenvs()})
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- parse and strip errors
                local lines = errors and tostring(errors):split('\n', {plain = true}) or {}
                if not option.get("verbose") then

                    -- find the start line of error
                    local start = 0
                    for index, line in ipairs(lines) do
                        if line:find("Error:", 1, true) or line:find("错误：", 1, true) then
                            start = index
                            break
                        end
                    end

                    -- get 16 lines of errors
                    if start > 0 then
                        lines = table.slice(lines, start, start + ((#lines - start > 16) and 16 or (#lines - start)))
                    end
                end

                -- raise compiling errors
                local results = #lines > 0 and table.concat(lines, "\n") or ""
                if not option.get("verbose") then
                    results = results .. "\n  ${yellow}> in ${bright}" .. sourcefile
                end
                raise(results)
            end
        },
        finally
        {
            function (ok, outdata, errdata)

                -- generate the dependent includes
                if depfile and os.isfile(depfile) then
                    if dependinfo then
                        -- it use makefile/gcc compatiable format
                        dependinfo.depfiles_format = "gcc"
                        dependinfo.depfiles = io.readfile(depfile, {continuation = "\\"})
                    end

                    -- remove the temporary dependent file
                    os.tryrm(depfile)
                end
            end
        }
    }
end
