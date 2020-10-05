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
-- @file        depend.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("private.tools.cl.parse_deps", {alias = "parse_deps_cl"})
import("private.tools.cl.parse_deps_json", {alias = "parse_deps_cl_json"})
import("private.tools.rc.parse_deps", {alias = "parse_deps_rc"})
import("private.tools.gcc.parse_deps", {alias = "parse_deps_gcc"})

-- load depfiles
function _load_depfiles(parser, dependinfo, depfiles)
    depfiles = parser(depfiles)
    if depfiles then
        if dependinfo.files then
            table.join2(dependinfo.files, depfiles)
        else
            dependinfo.files = depfiles
        end
    end
end

-- load dependent info from the given file (.d)
function load(dependfile)

    if os.isfile(dependfile) then
        -- may be the depend file has been incomplete when if the compilation process is abnormally interrupted
        local dependinfo = try { function() return io.load(dependfile) end }
        if dependinfo then
            -- attempt to load depfiles from the compilers
            if dependinfo.depfiles_gcc then
                _load_depfiles(parse_deps_gcc, dependinfo, dependinfo.depfiles_gcc)
                dependinfo.depfiles_gcc = nil
            elseif dependinfo.depfiles_cl_json then
                _load_depfiles(parse_deps_cl_json, dependinfo, dependinfo.depfiles_cl_json)
                dependinfo.depfiles_cl_json = nil
            elseif dependinfo.depfiles_cl then
                _load_depfiles(parse_deps_cl, dependinfo, dependinfo.depfiles_cl)
                dependinfo.depfiles_cl = nil
            elseif dependinfo.depfiles_rc then
                _load_depfiles(parse_deps_rc, dependinfo, dependinfo.depfiles_rc)
                dependinfo.depfiles_rc = nil
            end
            return dependinfo
        end
    end
end

-- save dependent info to file
function save(dependinfo, dependfile)
    io.save(dependfile, dependinfo)
end

-- the dependent info is changed?
--
-- if not depend.is_changed(dependinfo, {filemtime = os.mtime(objectfile), values = {...}}) then
--      return
-- end
--
function is_changed(dependinfo, opt)

    -- empty depend info? always be changed
    local files = dependinfo.files or {}
    local values = dependinfo.values or {}
    if #files == 0 and #values == 0 then
        return true
    end

    -- check the dependent files are changed?
    local lastmtime = opt.lastmtime or 0
    _g.files_mtime = _g.files_mtime or {}
    local files_mtime = _g.files_mtime
    for _, file in ipairs(files) do

        -- get and cache the file mtime
        local mtime = files_mtime[file] or os.mtime(file)
        files_mtime[file] = mtime

        -- source and header files have been changed or not exists?
        if mtime == 0 or mtime > lastmtime then
            return true
        end
    end

    -- check the dependent values are changed?
    local depvalues = values
    local optvalues = opt.values or {}
    if #depvalues ~= #optvalues then
        return true
    end
    for idx, depvalue in ipairs(depvalues) do
        local optvalue = optvalues[idx]
        local deptype = type(depvalue)
        local opttype = type(optvalue)
        if deptype ~= opttype then
            return true
        elseif deptype == "string" and depvalue ~= optvalue then
            return true
        elseif deptype == "table" then
            for subidx, subvalue in ipairs(depvalue) do
                if subvalue ~= optvalue[subidx] then
                    return true
                end
            end
        end
    end

    -- check the dependent files list are changed?
    local optfiles = opt.files
    if optfiles then
        for idx, file in ipairs(files) do
            if file ~= optfiles[idx] then
                return true
            end
        end
    end
end

-- on changed for the dependent files and values
--
-- e.g.
--
-- depend.on_changed(function ()
--     -- do some thing
--     -- ..
--
--     -- maybe need update dependent files
--     dependinfo.files = {""}
--
--     -- return new dependinfo (optional)
--     return {files = {}, ..}
--
-- end, {dependfile = "/xx/xx",
--       values = {compinst:program(), compflags},
--       files = {sourcefile, ...}})
--
function on_changed(callback, opt)

    -- get files
    opt = opt or {}
    assert(opt.files, "depend.on_changed(): please set files list!")

    -- get dependfile
    local dependfile = opt.dependfile
    if not dependfile then
        dependfile = project.tmpfile(table.concat(table.wrap(opt.files), ""))
    end

    -- load dependent info
    local dependinfo = option.get("rebuild") and {} or (load(dependfile) or {})

    -- need build this object?
    -- @note we use mtime(dependfile) instead of mtime(objectfile) to ensure the object file is is fully compiled.
    -- @see https://github.com/xmake-io/xmake/issues/748
    if not is_changed(dependinfo, {lastmtime = opt.lastmtime or os.mtime(dependfile), values = opt.values}) then
        return
    end

    -- do callback if changed and maybe files and values will be updated
    dependinfo = callback() or {}

    -- update files and values to the dependent file
    dependinfo.files = dependinfo.files or {}
    table.join2(dependinfo.files, opt.files)
    if opt.values then
        dependinfo.values = dependinfo.values or {}
        table.join2(dependinfo.values, opt.values)
    end
    save(dependinfo, dependfile)
end
