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

-- use the same key for relative/absolute aliases and case-insensitive filesystems
function _normalize_path(filepath, rootdir)
    local normalized = path.normalize(path.absolute(filepath, rootdir))
    return os.fscase() and normalized or normalized:lower()
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

    sourcefile = _normalize_path(sourcefile)

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
        for _, macro in ipairs(custom_macros) do
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
        local ext = path.extension(sourcefile):lower()
        if ext ~= ".h" and ext ~= ".hpp" then
            basenames:insert(path.basename(sourcefile))
        end
    end
    return basenames
end

-- reuse the macro scanner's stripped content when available
function _get_file_includes(filepath)
    local includes = memcache.get("qt.moc.includes", filepath)
    if includes == nil then
        local raw = memcache.get("qt.moc.rawfile", filepath)
        local content = raw and raw.clean_content or _strip_comments(io.readfile(filepath))
        includes = {}
        if content:find("include", 1, true) then
            for line in content:gmatch("[^\r\n]+") do
                local bracket, inc = line:match('^%s*#%s*include%s*(["<])([^">]+)[">]')
                if inc then
                    table.insert(includes, {path = inc, is_angle = bracket == "<"})
                end
            end
        end
        memcache.set("qt.moc.includes", filepath, includes)
    end
    return includes
end

-- do not recursively scan Qt/package include trees
function _get_local_includedirs(target)
    local dirs = {}
    local values, sources = target:get_from("includedirs", "*")
    for idx, value in ipairs(values) do
        if not sources[idx]:find("package::", 1, true) then
            for _, dir in ipairs(value) do
                table.insert(dirs, _normalize_path(dir))
            end
        end
    end
    return table.unique(dirs)
end

function _resolve_include_file(inc, curdir, includedirs, cache)
    if not inc.is_angle then
        local filepath = _normalize_path(inc.path, curdir)
        if os.isfile(filepath) then
            return filepath
        end
    end
    local resolved = cache[inc.path]
    if resolved == nil then
        resolved = false
        for _, dir in ipairs(includedirs) do
            local filepath = _normalize_path(inc.path, dir)
            if os.isfile(filepath) then
                resolved = filepath
                break
            end
        end
        cache[inc.path] = resolved
    end
    return resolved or nil
end

-- preserve fallback matching for generated moc_*.cpp and unresolved header includes
function _match_include(inc, candidates)
    local name = path.normalize(inc)
    if not os.fscase() then
        name = name:lower()
    end
    local basename = path.basename(name)
    local is_moc = basename:startswith("moc_") and path.extension(name) == ".cpp"
    if is_moc then
        basename = basename:sub(5)
    elseif path.extension(name) ~= ".h" and path.extension(name) ~= ".hpp" then
        return
    end
    local files = candidates[basename]
    if not files then
        return
    end
    local matches = {}
    local incdir = path.directory(name)
    for _, filepath in ipairs(files) do
        local candidate = is_moc and path.directory(filepath) or filepath
        local suffix = is_moc and incdir or name
        if incdir == "." or candidate == suffix or candidate:endswith(path.sep() .. suffix) then
            table.insert(matches, filepath)
        end
    end
    return matches
end

-- traverse only reachable local headers, once per target, when basename matching is insufficient
function _scan_included_headers(target, sourcefiles, headerfiles_keys, unmatched_entries)
    local remaining = #unmatched_entries
    local unmatched = {}
    local candidates = {}
    for _, entry in ipairs(unmatched_entries) do
        unmatched[entry.key] = true
        local basename = path.basename(entry.key)
        candidates[basename] = candidates[basename] or {}
        table.insert(candidates[basename], entry.key)
    end
    local includedirs = _get_local_includedirs(target)
    local rootdir = _normalize_path(os.curdir())
    local rootprefix = rootdir:endswith(path.sep()) and rootdir or rootdir .. path.sep()
    local found = hashset.new()
    local visited = hashset.new()
    local cache = {}
    local queue = table.clone(sourcefiles)
    local head = 1
    while head <= #queue and remaining > 0 do
        local filepath = _normalize_path(queue[head])
        head = head + 1
        if not visited:has(filepath) and os.isfile(filepath) then
            visited:insert(filepath)
            local curdir = path.directory(filepath)
            for _, inc in ipairs(_get_file_includes(filepath)) do
                local resolved = _resolve_include_file(inc, curdir, includedirs, cache)
                local matches = resolved and {resolved} or _match_include(inc.path, candidates)
                for _, matched in ipairs(matches) do
                    if unmatched[matched] then
                        found:insert(matched)
                        unmatched[matched] = nil
                        remaining = remaining - 1
                    end
                    local ext = path.extension(matched):lower()
                    local is_header = headerfiles_keys:has(matched)
                    if (is_header or matched:startswith(rootprefix)) and
                       (is_header or ext == ".h" or ext == ".hpp" or ext == ".hh" or
                        ext == ".hxx" or ext == ".h++" or ext == ".inl" or ext == "") then
                        if not visited:has(matched) then
                            table.insert(queue, matched)
                        end
                    end
                end
                if remaining == 0 then
                    break
                end
            end
        end
    end
    return found
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
    local sourcefiles_set = hashset.new()
    for _, sourcefile in ipairs(sourcefiles) do
        sourcefiles_set:insert(_normalize_path(sourcefile))
    end
    local source_basenames = _get_source_basenames(sourcefiles)

    local moc_headers = {}
    local unmatched_entries = {}
    local headerfiles_keys = hashset.new()
    for _, headerfile in ipairs(headerfiles) do
        local ext = path.extension(headerfile):lower()
        if ext == ".h" or ext == ".hpp" then
            local key = _normalize_path(headerfile)
            headerfiles_keys:insert(key)
            if not sourcefiles_set:has(key) and has_qt_moc_macros(headerfile, custom_macros) then
                local basename = path.basename(headerfile)
                if source_basenames:has(basename) then
                    table.insert(moc_headers, headerfile)
                else
                    table.insert(unmatched_entries, {file = headerfile, key = key})
                end
            end
        end
    end

    -- lazily traverse #include graph if headers with Qt macros have no same-basename source
    if #unmatched_entries > 0 then
        local found_keys = _scan_included_headers(target, sourcefiles, headerfiles_keys, unmatched_entries)
        for _, entry in ipairs(unmatched_entries) do
            if found_keys:has(entry.key) then
                table.insert(moc_headers, entry.file)
            end
        end
    end

    return moc_headers
end
