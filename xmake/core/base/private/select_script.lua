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
-- @file        select_script.lua
--

-- load modules
local table = require("base/table")
local utils = require("base/utils")

-- match pattern, matched mode: plat|arch, excluded mode: !plat|arch
function _match_pattern(pattern, plat, arch, opt)
    opt = opt or {}
    local excluded = opt.excluded
    local subhost = opt.subhost or os.subhost()
    local subarch = opt.subarch or os.subarch()

    -- support native arch, e.g. macosx|native
    -- @see https://github.com/xmake-io/xmake/issues/4657
    if pattern:find("native", 1, true) then
        local splitinfo = pattern:split("|")
        local pattern_plat = splitinfo[1]
        local pattern_arch = splitinfo[2]
        if pattern_arch and pattern_plat:trim("!") == subhost then
            pattern_arch = pattern_arch:gsub("native", subarch)
            pattern = pattern_plat .. "|" .. pattern_arch
        end
    end
    local is_excluded_pattern = pattern:find('!', 1, true)
    if excluded and is_excluded_pattern then
        return not ('!' .. plat .. '|' .. arch):match('^' .. pattern .. '$') and
               not (plat .. '|!' .. arch):match('^' .. pattern .. '$') and
               not ('!' .. plat):match('^' .. pattern .. '$')
    elseif not is_excluded_pattern then
        return (plat .. '|' .. arch):match('^' .. pattern .. '$') or plat:match('^' .. pattern .. '$')
    end
end

-- match patterns
function _match_patterns(patterns, plat, arch, opt)
    for _, pattern in ipairs(patterns) do
        if _match_pattern(pattern, plat, arch, opt) then
            return true
        end
    end
end

-- mattch the script pattern
--
-- @note interpreter has converted pattern to a lua pattern ('*' => '.*')
--
-- matched pattern:
--  plat|arch@subhost|subarch
--
-- e.g.
--
-- `@linux`
-- `@linux|x86_64`
-- `@macosx,linux`
-- `android@macosx,linux`
-- `android|armeabi-v7a@macosx,linux`
-- `android|armeabi-v7a,iphoneos@macosx,linux|x86_64`
-- `android|armeabi-v7a@linux|x86_64`
-- `linux|*`
--
-- excluded pattern:
--  !plat|!arch@!subhost|!subarch
--
-- e.g.
--
-- `@!linux`
-- `@!linux|x86_64`
-- `@!macosx,!linux`
-- `!android@macosx,!linux`
-- `android|!armeabi-v7a@macosx,!linux`
-- `android|armeabi-v7a,!iphoneos@macosx,!linux|x86_64`
-- `!android|armeabi-v7a@!linux|!x86_64`
-- `!linux|*`
--
function _match_script(pattern, opt)
    opt = opt or {}
    local splitinfo = pattern:split("@", {strict = true, plain = true})
    local plat_part = splitinfo[1]
    local host_part = splitinfo[2]
    local plat_patterns
    if plat_part and #plat_part > 0 then
        plat_patterns = plat_part:split(",", {plain = true})
    end
    local host_patterns
    if host_part and #host_part > 0 then
        host_patterns = host_part:split(",", {plain = true})
    end
    local plat = opt.plat or ""
    local arch = opt.arch or ""
    local subhost = opt.subhost or os.subhost()
    local subarch = opt.subarch or os.subarch()
    if plat_patterns and #plat_patterns > 0 then
        if _match_patterns(plat_patterns, plat, arch, opt) then
            if host_patterns and #host_patterns > 0 and
                not _match_patterns(host_patterns, subhost, subarch, opt) then
                return false
            end
            return true
        end
    else
        if host_patterns and #host_patterns > 0 then
            return _match_patterns(host_patterns, subhost, subarch, opt)
        end
    end
end

-- select the matched pattern script for the current platform/architecture
function select_script(scripts, opt)
    opt = opt or {}
    local result = nil
    if type(scripts) == "function" then
        result = scripts
    elseif type(scripts) == "table" then
        local script_matched
        for pattern, script in pairs(scripts) do
            if not pattern:startswith("__") and _match_script(pattern, opt) then
                script_matched = script
                break
            end
        end
        if not script_matched then
            local scripts_fallback = {}
            local patterns_fallback = {}
            local excluded_opt = table.join(opt, {excluded = true})
            for pattern, script in pairs(scripts) do
                if not pattern:startswith("__") and _match_script(pattern, excluded_opt) then
                    table.insert(scripts_fallback, script)
                    table.insert(patterns_fallback, pattern)
                end
            end
            script_matched = scripts_fallback[1]
            if script_matched and #scripts_fallback > 0 then
                local conflict_patterns = {patterns_fallback[1]}
                for idx, script in ipairs(scripts_fallback) do
                    local pattern = patterns_fallback[idx]
                    if script ~= script_matched then
                        table.insert(conflict_patterns, pattern)
                    end
                end
                if #conflict_patterns > 1 then
                    utils.warning("multiple script patterns are matched, %s", table.concat(conflict_patterns, ", "))
                end
            end
        end
        result = script_matched or scripts["__generic__"]
    end
    return result
end

return select_script
