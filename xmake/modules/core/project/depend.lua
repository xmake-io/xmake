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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        depend.lua
--

-- load dependent info from the given file (.d) 
function load(dependfile)
    if os.isfile(dependfile) then
        -- may be the depend file has been incomplete when if the compilation process is abnormally interrupted
        return try { function() return io.load(dependfile) end }
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
    local lastmtime = nil
    _g.file_results = _g.file_results or {}
    for _, file in ipairs(files) do

        -- optimization: this file has been not checked?
        local status = _g.file_results[file]
        if status == nil then

            -- optimization: only uses the mtime of first object file
            lastmtime = lastmtime or opt.lastmtime or 0

            -- source and header files have been changed?
            if not os.isfile(file) or os.mtime(file) > lastmtime then

                -- mark this file as changed
                _g.file_results[file] = true
                return true
            end

            -- mark this file as not changed
            _g.file_results[file] = false
        
        -- has been checked and changed?
        elseif status then
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
