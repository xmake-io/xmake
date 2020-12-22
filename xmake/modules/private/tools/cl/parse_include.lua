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
-- @file        parse_include.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")
import("core.tool.toolchain")
import("core.cache.detectcache")
import("lib.detect.find_tool")
import("private.tools.vstool")

-- probe include note prefix from cl
function _probe_include_note_from_cl()
    local key = "cldeps.parse_include.note"
    local note = detectcache:get(key)
    if not note then
        local cl = find_tool("cl")
        if cl then
            local projectdir = os.tmpfile() .. ".cldeps"
            local sourcefile = path.join(projectdir, "main.c")
            local headerfile = path.join(projectdir, "foo.h")
            local objectfile = sourcefile .. ".obj"
            local outdata = try { function()
                local runenvs = toolchain.load("msvc"):runenvs()
                local argv = {"-nologo", "-showIncludes", "-c", "-Fo" .. objectfile, sourcefile}
                io.writefile(headerfile, "\n")
                io.writefile(sourcefile, [[
                    #include "foo.h"
                    int main (int argc, char** argv) {
                        return 0;
                    }
                ]])
                return vstool.iorunv(cl.program, argv, {envs = runenvs, curdir = projectdir})
            end}
            if outdata then
                for _, line in ipairs(outdata:split('\n', {plain = true})) do
                    note = line:match("^(.-:.-: )")
                    if note then
                        break
                    end
                end
            end
            os.tryrm(projectdir)
        end
        detectcache:set(key, note)
        detectcache:save()
    end
    return note
end

-- get include notes prefix, e.g. "Note: including file: "
--
-- @note we cannot get better solution to distinguish between `includes` and `error infos`
--
function _get_include_notes()
    local notes = _g.notes
    if not notes then
        notes = {}
        local note = _probe_include_note_from_cl()
        if note then
            table.insert(notes, note)
        end
        table.join2(notes, {
            "Note: including file: ", -- en
            "注意: 包含文件: ", -- zh
            "Remarque : inclusion du fichier : ", -- fr
            "メモ: インクルード ファイル: " -- jp
        })
        _g.notes = notes
    end
    return notes
end

-- main entry
function main(line)
    local notes = _get_include_notes()
    for idx, note in ipairs(notes) do
        if line:startswith(note) then
            -- optimization: move this note to head
            if idx ~= 1 then
                table.insert(notes, 1, note)
            end
            return line:sub(#note):trim()
        end
    end
end

