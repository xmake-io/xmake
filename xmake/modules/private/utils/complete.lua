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
-- @author      OpportunityLiu, glcraft
-- @file        complete.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("private.utils.completer")

function main(pos, config, ...)

    local comp = completer.new(pos, config, {...})

    local word = table.concat(comp:words(), " ") or ""
    position = tonumber(pos) or 0

    local has_space = word:endswith(" ") or position > #word
    word = word:trim()

    local argv = os.argv(word)

    if argv[1] then

        -- normailize word to remove "xmake"
        if is_host("windows") and argv[1]:lower() == "xmake.exe" then
            argv[1] = "xmake"
        end
        if argv[1] == "xmake" then
            table.remove(argv, 1)
        end
    end

    local items = {}
    local tasks = task.names()
    for _, name in ipairs(tasks) do
        items[name] = option.taskmenu(name)
    end

    if has_space then
        comp:complete(items, argv, "")
    else
        local completing = table.remove(argv)
        comp:complete(items, argv, completing or "")
    end
end

