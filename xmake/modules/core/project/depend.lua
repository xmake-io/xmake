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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        depend.lua
--

-- imports
import("core.base.option")
import("core.project.project")

-- load depfiles
function _load_depfiles(parser, dependinfo, depfiles, opt)
    depfiles = parser(depfiles, opt)
    if depfiles then
        if dependinfo.files then
            table.join2(dependinfo.files, depfiles)
        else
            dependinfo.files = depfiles
        end
    end
end

-- get depfiles parser
function _get_depfiles_parser(depfiles_format)
    assert(depfiles_format, "no depfiles format")
    local depfiles_parsers = _g._depfiles_parsers
    if depfiles_parsers == nil then
        depfiles_parsers = {}
        _g._depfiles_parsers = depfiles_parsers
    end
    local parser = depfiles_parsers[depfiles_format]
    if parser == nil then
        parser = import("core.tools." .. depfiles_format .. ".parse_deps", {anonymous = true})
        depfiles_parsers[depfiles_format] = parser or false
    end
    return parser or nil
end

-- load dependent info from the given file (.d)
--
-- @param dependfile    the depend file path
-- @param opt           the options, e.g. {target = target}
-- @return              the depend info table, or nil if not found
--
function load(dependfile, opt)
    if os.isfile(dependfile) then
        -- may be the depend file has been incomplete when if the compilation process is abnormally interrupted
        local dependinfo = try { function() return io.load(dependfile) end }
        if dependinfo then
            -- attempt to load depfiles from the compilers
            local depfiles = dependinfo.depfiles
            if depfiles then
                local depfiles_parser = _get_depfiles_parser(dependinfo.depfiles_format)
                _load_depfiles(depfiles_parser, dependinfo, depfiles, opt)
                dependinfo.depfiles = nil
            end
            return dependinfo
        end
    end
end

-- show diagnosis info?
function _is_show_diagnosis_info()
    local show = _g.is_show_diagnosis_info
    if show == nil then
        if project.policy("diagnosis.check_build_deps") then
            show = true
        else
            show = false
        end
        _g.is_show_diagnosis_info = show
    end
    return show
end

-- save dependent info to file
--
-- @param dependinfo    the depend info table {files = {}, values = {}}
-- @param dependfile    the depend file path
--
function save(dependinfo, dependfile)
    io.save(dependfile, dependinfo)
end

-- is the dependent info changed?
--
-- @param dependinfo    the depend info table from depend.load()
-- @param opt           the options
--                      - lastmtime: the last modification time to compare
--                      - values: the depend values to compare
--                      - files: the depend files (optional, from dependinfo.files)
--                      - timecache: enable time cache for performance (optional)
-- @return              true if changed
--
-- @code
-- if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = {program, flags}}) then
--      return
-- end
-- @endcode
--
function is_changed(dependinfo, opt)

    -- empty depend info? always be changed
    local files = table.wrap(dependinfo.files)
    local values = table.wrap(dependinfo.values)
    if #files == 0 and #values == 0 then
        return true
    end

    -- check whether the dependent files are changed
    local timecache = opt.timecache
    local lastmtime = opt.lastmtime or 0
    _g.files_mtime = _g.files_mtime or {}
    local files_mtime = _g.files_mtime
    for _, file in ipairs(files) do

        -- get and cache the file mtime
        local mtime
        if timecache then
            mtime = files_mtime[file]
            if mtime == nil then
                mtime = os.mtime(file)
                files_mtime[file] = mtime
            end
        else
            mtime = os.mtime(file)
        end

        -- source and header files have been changed or not exists?
        if mtime == 0 or mtime > lastmtime then
            if _is_show_diagnosis_info() then
                cprint("${color.warning}[check_build_deps]: file %s is changed, mtime: %s, lastmtime: %s", file, mtime, lastmtime)
            end
            return true
        end
    end

    -- check whether the dependent values are changed
    local depvalues = values
    local optvalues = table.wrap(opt.values)
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
            if _is_show_diagnosis_info() then
                cprint("${color.warning}[check_build_deps]: value %s != %s", depvalue, optvalue)
            end
            return true
        elseif deptype == "table" then
            if #depvalue ~= #optvalue then
                return true
            end
            for subidx, subvalue in ipairs(depvalue) do
                if subvalue ~= optvalue[subidx] then
                    if _is_show_diagnosis_info() then
                        cprint("${color.warning}[check_build_deps]: value %s != %s at index %d", subvalue, optvalue[subidx], subidx)
                    end
                    return true
                end
            end
        end
    end

    -- check whether the dependent files list are changed
    if opt.files then
        local optfiles = table.wrap(opt.files)
        if #files ~= #optfiles then
            return true
        end
        for idx, file in ipairs(files) do
            if file ~= optfiles[idx] then
                if _is_show_diagnosis_info() then
                    cprint("${color.warning}[check_build_deps]: file %s != %s at index %d", file, optfiles[idx], idx)
                end
                return true
            end
        end
    end
end

-- run callback only when dependent files or values have changed
--
-- @param callback      the callback function to run when changed
-- @param opt           the options
--                      - dependfile: the depend cache file path (required)
--                      - files: the source files to track
--                      - values: the values to track (e.g. flags, program)
--
-- @code
-- depend.on_changed(function ()
--     -- do build work here
-- end, {dependfile = target:dependfile(objectfile),
--       files = {sourcefile},
--       values = {compinst:program(), compflags}})
-- @endcode
--
function on_changed(callback, opt)
    opt = opt or {}

    -- dry run? we only do callback directly and do not change any status
    if opt.dryrun then
        return callback()
    end

    -- get files
    assert(opt.files, "depend.on_changed(): please set files list!")

    -- get dependfile
    local dependfile = opt.dependfile
    if not dependfile then
        dependfile = project.tmpfile(table.concat(table.wrap(opt.files), ""))
    end

    -- load dependent info
    local dependinfo = opt.changed and {} or (load(dependfile) or {})

    -- @note we use mtime(dependfile) instead of mtime(objectfile) to ensure the object file is is fully compiled.
    -- @see https://github.com/xmake-io/xmake/issues/748
    if not is_changed(dependinfo, {
            timecache = opt.timecache,
            lastmtime = opt.lastmtime or os.mtime(dependfile),
            values = opt.values, files = opt.files}) then
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
