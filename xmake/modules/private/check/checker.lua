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
-- @file        checker.lua
--

-- imports
import("core.base.option")

-- get all checkers
function checkers()
    local checkers = _g._CHECKERS
    if not checkers then
        checkers = {
            -- target api checkers
            ["api.target.version"]       = {description = "Check version configuration in target."},
            ["api.target.kind"]          = {description = "Check kind configuration in target.", build = true},
            ["api.target.strip"]         = {description = "Check strip configuration in target.", build = true},
            ["api.target.optimize"]      = {description = "Check optimize configuration in target.", build = true},
            ["api.target.symbols"]       = {description = "Check symbols configuration in target.", build = true},
            ["api.target.fpmodels"]      = {description = "Check fpmodels configuration in target.", build = true},
            ["api.target.warnings"]      = {description = "Check warnings configuration in target.", build = true},
            ["api.target.languages"]     = {description = "Check languages configuration in target.", build = true},
            ["api.target.vectorexts"]    = {description = "Check vectorexts configuration in target.", build = true},
            ["api.target.exceptions"]    = {description = "Check exceptions configuration in target.", build = true},
            ["api.target.encodings"]     = {description = "Check encodings configuration in target.", build = true},
            ["api.target.packages"]      = {description = "Check packages configuration in target."},
            ["api.target.files"]         = {description = "Check files configuration in target."},
            ["api.target.headerfiles"]   = {description = "Check header files configuration in target."},
            ["api.target.installfiles"]  = {description = "Check install files configuration in target."},
            ["api.target.configfiles"]   = {description = "Check config files configuration in target."},
            ["api.target.linkdirs"]      = {description = "Check linkdirs configuration in target.", build = true},
            ["api.target.includedirs"]   = {description = "Check includedirs configuration in target.", build = true},
            ["api.target.frameworkdirs"] = {description = "Check frameworkdirs configuration in target.", build = true},
            ["api.target.cflags"]        = {description = "Check c compiler flags configuration in target."},
            ["api.target.cxflags"]       = {description = "Check c/c++ compiler flags configuration in target."},
            ["api.target.cxxflags"]      = {description = "Check c++ compiler flags configuration in target."},
            ["api.target.asflags"]       = {description = "Check assembler flags configuration in target."},
            ["api.target.ldflags"]       = {description = "Check binary linker flags configuration in target."},
            ["api.target.shflags"]       = {description = "Check shared library linker flags configuration in target."},
            ["api.target.license"]       = {description = "Check license in target and packages.", build = true},
            -- cuda checkers
            ["cuda.devlink"]             = {description = "Check devlink for targets.", build_failure = true},
            -- clang tidy checker
            ["clang.tidy"]               = {description = "Check project code using clang-tidy.", showstats = false}
        }
        _g._CHECKERS = checkers
    end
    return checkers
end

-- complete checkers
function complete(complete, opt)
    return try
    {
        function ()
            local list = {}
            local groupstats = {}
            for name, _ in table.orderpairs(checkers()) do
                local groupname = name:split(".", {plain = true})[1]
                groupstats[groupname] = (groupstats[groupname] or 0) + 1
                if not complete then
                    local limit = 16
                    if groupstats[groupname] < limit then
                        table.insert(list, name)
                    elseif groupstats[groupname] == limit then
                        table.insert(list, "...")
                    end
                elseif name:startswith(complete) then
                    table.insert(list, name)
                end
            end
            return list
        end
    }
end

-- update stats
function update_stats(level, count)
    local stats = _g.stats
    if not stats then
        stats = {}
        _g.stats = stats
    end
    count = count or 1
    stats[level] = (stats[level] or 0) + count
end

-- show stats
function show_stats()
    local stats = _g.stats or {}
    cprint("${bright}%d${clear} notes, ${color.warning}%d${clear} warnings, ${color.error}%d${clear} errors", stats.note or 0, stats.warning or 0, stats.error or 0)
end
