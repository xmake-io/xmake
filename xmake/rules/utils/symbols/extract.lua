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
-- @file        xmake.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.platform.platform")
import("lib.detect.find_tool")

-- need generate symbols?
function _need_symbols(target)
    local strip = target:get("strip")
    local targetkind = target:targetkind()
    return target:get("symbols") == "debug" and (strip == "all" or strip == "debug") and (targetkind == "binary" or targetkind == "shared")
end

-- the main entry
function main(target, opt)

    -- need generate symbols?
    if not _need_symbols(target) then
        return
    end

    -- find strip
    local strip = platform.tool("strip")
    if not strip then
        return
    end

    -- trace progress info
    local targetfile = target:targetfile()
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    if option.get("verbose") then
        cprint(progress_prefix .. "${dim color.build.target}stripping.$(mode) %s", opt.progress, path.filename(targetfile))
    else
        cprint(progress_prefix .. "${color.build.target}stripping.$(mode) %s", opt.progress, path.filename(targetfile))
    end

    -- strip it
    local strip_argv = {}
    if is_plat("macosx", "iphoneos", "watchos") then
        -- do not support `-s`, we can only strip debug symbols 
        local arch = get_config("arch")
        if arch then
            table.insert(strip_argv, "-arch")
            table.insert(strip_argv, arch)
        end
        table.insert(strip_argv, "-S")
    else
        -- -s/--strip-all for gnu strip
        table.insert(strip_argv, "-s")
    end
    table.insert(strip_argv, targetfile)
    os.vrunv(strip, strip_argv, {dryrun = option.get("dry-run")})
end

