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

-- normalize path to a canonical lookup key across separators and case sensitivity
function _normalize_path(filepath, rootdir, fscase)
    if fscase == nil then
        fscase = os.fscase()
    end
    local normalized = path.normalize(path.absolute(filepath, rootdir or os.curdir()))
    if not fscase then
        normalized = normalized:lower()
    end
    return normalized
end

-- check whether normalized filepath resides under normalized rootdir
function _is_path_under(filepath, rootdir, fscase)
    if not rootdir or rootdir == "" then
        return false
    end
    if fscase == nil then
        fscase = os.fscase()
    end
    local p = fscase and filepath or filepath:lower()
    local root = fscase and rootdir or rootdir:lower()
    if p == root then
        return true
    end
    local last = root:sub(-1)
    if last ~= "/" and last ~= "\\" then
        return p:startswith(root .. "/") or p:startswith(root .. "\\")
    end
    return p:startswith(root)
end

-- strip C/C++ comments from source content
function _strip_comments(content)
    -- strip block comments /* ... */
    content = content:gsub("/%*.-%*/", "")
    -- strip line comments // ...
    content = content:gsub("//[^\r\n]*", "")
    return content
end

-- read and cache stripped content plus built-in Qt macro flags
function _get_raw_file(sourcefile, raw_key, rootdir, fscase)
    if not os.isfile(sourcefile) then
        return nil
    end

    raw_key = raw_key or _normalize_path(sourcefile, rootdir, fscase)
    local raw = memcache.get("qt.moc.rawfile", raw_key)
    if raw ~= nil then
        return raw
    end

    local content = io.readfile(sourcefile)
    if not content then
        return nil
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
    memcache.set("qt.moc.rawfile", raw_key, raw)
    return raw
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

    local rootdir = os.curdir()
    local fscase = os.fscase()
    local raw_key = _normalize_path(sourcefile, rootdir, fscase)
    local cache_key = _get_cache_key(raw_key, custom_macros)
    local fileinfo = memcache.get("qt.moc.fileinfo", cache_key)
    if fileinfo ~= nil then
        return fileinfo
    end

    local raw = _get_raw_file(sourcefile, raw_key, rootdir, fscase)
    if not raw then
        fileinfo = {has_moc = false, has_private_slot = false}
        memcache.set("qt.moc.fileinfo", cache_key, fileinfo)
        return fileinfo
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

-- extract and cache #include directives from comment-stripped source content
function _get_file_includes(filepath, file_key, rootdir, fscase)
    local includes = memcache.get("qt.moc.includes", file_key)
    if includes ~= nil then
        return includes
    end

    local raw = _get_raw_file(filepath, file_key, rootdir, fscase)
    if not raw then
        return {}
    end

    includes = {}
    local clean_content = raw.clean_content
    if clean_content and clean_content:find("include", 1, true) then
        for line in clean_content:gmatch("[^\r\n]+") do
            local bracket, inc = line:match('^%s*#%s*include%s*(["<])([^">]+)[">]')
            if inc then
                table.insert(includes, {path = inc, is_angle = (bracket == "<")})
            end
        end
    end
    memcache.set("qt.moc.includes", file_key, includes)
    return includes
end

-- collect project-local and dependent target includedirs, excluding package and system dirs
function _get_local_includedirs(target, rootdir, fscase)
    local rawdirs, sources
    if target.get_from then
        rawdirs, sources = target:get_from("includedirs", "*")
    else
        rawdirs = target:get("includedirs")
    end

    local dirs = {}
    local seen = hashset.new()
    for idx, entry in ipairs(rawdirs) do
        local source = sources and sources[idx]
        if not source or not source:find("package::", 1, true) then
            for _, dir in ipairs(entry) do
                local absdir = path.normalize(path.absolute(dir, rootdir))
                local key = fscase and absdir or absdir:lower()
                if not seen:has(key) and os.isdir(absdir) then
                    seen:insert(key)
                    table.insert(dirs, absdir)
                end
            end
        end
    end
    return dirs
end

-- resolve an #include path on disk via relative directory (for quoted includes) and local includedirs
function _resolve_include_file(inc, is_angle, curdir, includedirs, incdir_cache)
    if not is_angle and curdir then
        local candidate = path.normalize(path.absolute(inc, curdir))
        if os.isfile(candidate) then
            return candidate
        end
    end

    local cached = incdir_cache[inc]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    for _, dir in ipairs(includedirs) do
        local candidate = path.normalize(path.absolute(inc, dir))
        if os.isfile(candidate) then
            incdir_cache[inc] = candidate
            return candidate
        end
    end

    incdir_cache[inc] = false
    return nil
end

-- check whether an unresolved #include candidate matches an unmatched header path
function _is_fallback_match(cand, inc_norm, is_moc_cpp, inc_dir, has_slash)
    if is_moc_cpp then
        if not inc_dir then
            return true
        end
        local cand_dir = path.directory(cand.unix_key):gsub("\\", "/")
        return cand_dir == inc_dir or cand_dir:endswith("/" .. inc_dir)
    end
    if not has_slash then
        return true
    end
    return cand.unix_key == inc_norm or cand.unix_key:endswith("/" .. inc_norm)
end

-- match unresolved generated moc_*.cpp includes or headers outside target includedirs
function _match_fallback_candidates(inc, fscase, unmatched_by_key, unmatched_by_base)
    local ext = path.extension(inc):lower()
    local filename = path.filename(inc)
    local is_moc_cpp = filename:startswith("moc_") and ext == ".cpp"
    if not is_moc_cpp and ext ~= ".h" and ext ~= ".hpp" then
        return nil
    end

    local match_base = path.basename(inc):lower()
    if is_moc_cpp then
        match_base = match_base:sub(5)
    end
    local candidates = unmatched_by_base[match_base]
    if not candidates then
        return nil
    end

    local inc_norm = inc:gsub("\\", "/"):gsub("^%./", "")
    if not fscase then
        inc_norm = inc_norm:lower()
    end

    local inc_dir = nil
    if is_moc_cpp then
        local dir = path.directory(inc_norm)
        if dir ~= "." then
            inc_dir = dir
        end
    end
    local has_slash = (inc_norm:find("/", 1, true) ~= nil)

    local matched = nil
    for _, cand in ipairs(candidates) do
        if unmatched_by_key[cand.key] and _is_fallback_match(cand, inc_norm, is_moc_cpp, inc_dir, has_slash) then
            matched = matched or {}
            table.insert(matched, cand)
        end
    end
    return matched
end

-- check whether resolved include is a project-local header safe to expand transitively
function _is_traversable_header(filepath, file_key, headerfiles_keys, norm_rootdir, fscase)
    local ext = path.extension(filepath):lower()
    if ext ~= ".h" and ext ~= ".hpp" and ext ~= ".hh" and ext ~= ".hxx" and ext ~= ".h++" and ext ~= ".inl" and ext ~= "" and not headerfiles_keys:has(file_key) then
        return false
    end
    return headerfiles_keys:has(file_key) or _is_path_under(path.normalize(filepath), norm_rootdir, fscase)
end

-- scan one #include directive from a visited file node, returning true when all targets are matched
function _scan_single_include(inc_info, curdir, state)
    local resolved = _resolve_include_file(inc_info.path, inc_info.is_angle, curdir, state.includedirs, state.incdir_cache)
    if resolved then
        local res_key = _normalize_path(resolved, state.rootdir, state.fscase)
        state.mark_matched(res_key)
        if state.remaining == 0 then
            return true
        end
        if _is_traversable_header(resolved, res_key, state.headerfiles_keys, state.norm_rootdir, state.fscase) then
            state.enqueue(resolved, res_key)
        end
        return false
    end

    local matched = _match_fallback_candidates(inc_info.path, state.fscase, state.unmatched_by_key, state.unmatched_by_base)
    if not matched then
        return false
    end
    for _, cand in ipairs(matched) do
        state.mark_matched(cand.key)
        if os.isfile(cand.file) then
            state.enqueue(cand.file, cand.key)
        end
    end
    return state.remaining == 0
end

-- transitively scan #include graph from target sourcefiles for reachable unmatched headers
function _scan_included_headers(target, sourcefiles, headerfiles_keys, unmatched_entries)
    local found_keys = hashset.new()
    local state = {
        rootdir = os.curdir(),
        fscase = os.fscase(),
        headerfiles_keys = headerfiles_keys,
        unmatched_by_key = {},
        unmatched_by_base = {},
        remaining = 0,
        incdir_cache = {}
    }
    state.norm_rootdir = path.normalize(path.absolute(state.rootdir))
    state.includedirs = _get_local_includedirs(target, state.rootdir, state.fscase)

    for _, entry in ipairs(unmatched_entries) do
        state.unmatched_by_key[entry.key] = entry.file
        local base = path.basename(entry.file):lower()
        state.unmatched_by_base[base] = state.unmatched_by_base[base] or {}
        table.insert(state.unmatched_by_base[base], {
            key = entry.key,
            file = entry.file,
            unix_key = entry.key:gsub("\\", "/")
        })
        state.remaining = state.remaining + 1
    end
    if state.remaining == 0 then
        return found_keys
    end

    local visited = hashset.new()
    local queue = {}
    state.enqueue = function (filepath, key)
        if not visited:has(key) then
            visited:insert(key)
            table.insert(queue, {path = filepath, key = key})
        end
    end
    state.mark_matched = function (key)
        if state.unmatched_by_key[key] then
            found_keys:insert(key)
            state.unmatched_by_key[key] = nil
            state.remaining = state.remaining - 1
        end
    end

    -- seed BFS with existing files explicitly listed in target:sourcefiles()
    for _, sourcefile in ipairs(sourcefiles) do
        if os.isfile(sourcefile) then
            state.enqueue(sourcefile, _normalize_path(sourcefile, state.rootdir, state.fscase))
        end
    end

    local head = 1
    while head <= #queue and state.remaining > 0 do
        local item = queue[head]
        head = head + 1

        local curdir = path.directory(path.normalize(path.absolute(item.path, state.rootdir)))
        for _, inc_info in ipairs(_get_file_includes(item.path, item.key, state.rootdir, state.fscase)) do
            if _scan_single_include(inc_info, curdir, state) then
                break
            end
        end
    end

    return found_keys
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

    local rootdir = os.curdir()
    local fscase = os.fscase()
    local custom_macros = target:values("qt.moc.macros") or target:get("qt.moc.macros")
    local sourcefiles = target:sourcefiles()
    local sourcefiles_set = hashset.new()
    for _, sourcefile in ipairs(sourcefiles) do
        sourcefiles_set:insert(_normalize_path(sourcefile, rootdir, fscase))
    end
    local source_basenames = _get_source_basenames(sourcefiles)

    local moc_headers = {}
    local unmatched_entries = {}
    local headerfiles_keys = hashset.new()
    for _, headerfile in ipairs(headerfiles) do
        local ext = path.extension(headerfile):lower()
        if ext == ".h" or ext == ".hpp" then
            local key = _normalize_path(headerfile, rootdir, fscase)
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
