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
-- @file        utils.lua
--

-- imports
import("core.base.hashset")
import("core.cache.memcache")

-- generate cache key for sourcefile and custom_macros
function _get_cache_key(sourcefile, custom_macros)
    if not custom_macros then
        return sourcefile
    end
    if type(custom_macros) == "table" then
        return sourcefile .. "::" .. table.concat(table.wrap(custom_macros), ",")
    end
    return sourcefile .. "::" .. tostring(custom_macros)
end

-- strip C/C++ comments from source content
function _strip_comments(content)
    -- strip block comments /* ... */
    content = content:gsub("/%*.-%*/", "")
    -- strip line comments // ...
    content = content:gsub("//[^\r\n]*", "")
    return content
end

-- parse and cache Qt macro info from file
function get_file_info(sourcefile, custom_macros)
    if not sourcefile then
        return {has_moc = false, has_private_slot = false}
    end

    -- safe check: do not call io.readfile if file does not exist (e.g. always_added generated headers)
    -- do not cache not_found into memcache to avoid caching mutable file existence across build stages
    if not os.isfile(sourcefile) then
        return {has_moc = false, has_private_slot = false, not_found = true}
    end

    local cache_key = _get_cache_key(sourcefile, custom_macros)
    local fileinfo = memcache.get("qt.moc.fileinfo", cache_key)
    if fileinfo ~= nil then
        return fileinfo
    end

    local raw = memcache.get("qt.moc.rawfile", sourcefile)
    if raw == nil then
        local content = io.readfile(sourcefile)
        if not content then
            fileinfo = {has_moc = false, has_private_slot = false}
            memcache.set("qt.moc.fileinfo", cache_key, fileinfo)
            return fileinfo
        end

        local clean_content = _strip_comments(content)
        local has_private_slot = (clean_content:find("Q_PRIVATE_SLOT", 1, true) ~= nil)
        local has_standard_moc = false

        -- fast check: only test standard Qt macros if "Q_" exists
        if content:find("Q_", 1, true) then
            if clean_content:find("%f[%w_]Q_OBJECT%f[^%w_]") or
               clean_content:find("%f[%w_]Q_GADGET%f[^%w_]") or
               clean_content:find("%f[%w_]Q_GADGET_EXPORT%f[^%w_]") or
               clean_content:find("%f[%w_]Q_NAMESPACE%f[^%w_]") or
               clean_content:find("%f[%w_]Q_NAMESPACE_EXPORT%f[^%w_]") or
               clean_content:find("%f[%w_]Q_ENUM_NS%f[^%w_]") then
                has_standard_moc = true
            end
        end

        raw = {
            clean_content = clean_content,
            has_standard_moc = has_standard_moc,
            has_private_slot = has_private_slot
        }
        memcache.set("qt.moc.rawfile", sourcefile, raw)
    end

    local has_moc = raw.has_standard_moc
    if not has_moc and custom_macros and raw.clean_content then
        for _, macro in ipairs(table.wrap(custom_macros)) do
            if raw.clean_content:find("%f[%w_]" .. macro .. "%f[^%w_]") then
                has_moc = true
                break
            end
        end
    end

    fileinfo = {has_moc = has_moc, has_private_slot = raw.has_private_slot}
    memcache.set("qt.moc.fileinfo", cache_key, fileinfo)
    return fileinfo
end

-- check if the file contains Qt meta-object macros
function has_qt_moc_macros(sourcefile, custom_macros)
    local info = get_file_info(sourcefile, custom_macros)
    return info.has_moc
end

-- check if the file contains Q_PRIVATE_SLOT
function has_q_private_slot(sourcefile)
    local info = get_file_info(sourcefile)
    return info.has_private_slot
end

-- check if source file needs moc processing
function need_moc(target, sourcefile)
    -- check if target requires moc json collection (e.g. qt.qmltyperegistrar/qt.qmlplugin)
    local is_qmlplugin = (target:rule("qt.qmltyperegistrar") ~= nil or
                          target:data("qt.qmltyperegistrar") ~= nil or
                          target:values("qt.qmlplugin.import_name") ~= nil or
                          (target:get("qt.moc.flags") and table.contains(table.wrap(target:get("qt.moc.flags")), "--output-json")))
    if is_qmlplugin then
        return true
    end

    local custom_macros = target:values("qt.moc.macros") or target:get("qt.moc.macros")
    local fileinfo = get_file_info(sourcefile, custom_macros)
    return fileinfo.not_found or fileinfo.has_moc
end

-- get basenames of non-header source files
function _get_source_basenames(sourcefiles)
    local basenames = hashset.new()
    for _, sourcefile in ipairs(sourcefiles) do
        if not sourcefile:endswith(".h") and not sourcefile:endswith(".hpp") then
            basenames:insert(path.basename(sourcefile))
        end
    end
    return basenames
end

-- scan source files for #include statements matching candidate basenames
function _scan_included_basenames(sourcefiles, candidate_basenames)
    local included_basenames = hashset.new()
    for _, sourcefile in ipairs(sourcefiles) do
        if not sourcefile:endswith(".h") and not sourcefile:endswith(".hpp") and os.isfile(sourcefile) then
            local content = io.readfile(sourcefile)
            if content and content:find("#include", 1, true) then
                for inc in content:gmatch('#include%s+["<]([^">]+)[">]') do
                    local inc_base = path.basename(inc)
                    if inc_base:startswith("moc_") then
                        inc_base = inc_base:sub(5)
                    end
                    if candidate_basenames:has(inc_base) then
                        included_basenames:insert(inc_base)
                    end
                end
                if included_basenames:size() == candidate_basenames:size() then
                    break
                end
            end
        end
    end
    return included_basenames
end

-- automatically detect header files with Qt meta-object macros
function detect_moc_headers(target)
    if target:data("qt.moc.headers_scanned") then
        return {}
    end
    target:data_set("qt.moc.headers_scanned", true)

    local headerfiles = target:headerfiles()
    if not headerfiles or #headerfiles == 0 then
        return {}
    end

    local custom_macros = target:values("qt.moc.macros") or target:get("qt.moc.macros")
    local sourcefiles = target:sourcefiles()
    local sourcefiles_set = hashset.from(sourcefiles)
    local source_basenames = _get_source_basenames(sourcefiles)

    local moc_headers = {}
    local unmatched_headers = {}
    for _, headerfile in ipairs(headerfiles) do
        local ext = path.extension(headerfile):lower()
        if (ext == ".h" or ext == ".hpp") and not sourcefiles_set:has(headerfile) then
            if has_qt_moc_macros(headerfile, custom_macros) then
                local basename = path.basename(headerfile)
                if source_basenames:has(basename) then
                    table.insert(moc_headers, headerfile)
                else
                    table.insert(unmatched_headers, headerfile)
                end
            end
        end
    end

    -- lazily scan source files for #include if headers with Qt macros have no same-basename source
    if #unmatched_headers > 0 then
        local unmatched_basenames = hashset.new()
        for _, headerfile in ipairs(unmatched_headers) do
            unmatched_basenames:insert(path.basename(headerfile))
        end

        local included_basenames = _scan_included_basenames(sourcefiles, unmatched_basenames)
        for _, headerfile in ipairs(unmatched_headers) do
            if included_basenames:has(path.basename(headerfile)) then
                table.insert(moc_headers, headerfile)
            end
        end
    end

    return moc_headers
end
