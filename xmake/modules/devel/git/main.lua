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
-- @author      OpportunityLiu
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.cli")
import("lib.detect.find_tool")

function _append_command(argv, command)

    command = command:gsub("_", "-")
    table.insert(argv, command)

    return command
end

function _append_opt(argv, key, value)

    if #key > 1 then
        key = key:gsub("_", "-")
    end
    if type(value) == "boolean" then
        if not value then
            key = "no-" .. key
        end
        value = nil
    else
        value = tostring(value or " ")
    end

    local prefix = #key > 1 and "--" or "-"
    table.insert(argv, prefix .. key)
    if value ~= nil then
        table.insert(argv, value)
    end
end

function _append_opts(argv, opts)

    if opts.repodir then
        argv.repodir = opts.repodir
        opts.repodir = nil
    end

    for key, value in pairs(opts) do
        if type(value) == "table" then
            for _, v in ipairs(value) do
                _append_opt(argv, key, v)
            end
        else
            _append_opt(argv, key, value)
        end
    end
end

function _append_params(argv, params, last)

    -- insert options
    for i = 1, params.n do
        local param = params[i]
        if type(param) == "table" then
            _append_opts(argv, param)
        end
    end

    -- insert "--" for last operands
    if last then
        table.insert(argv, "--")
    end

    -- insert operands
    for i = 1, params.n do
        local param = params[i]
        if type(param) ~= "table" then
            if param ~= nil then
                table.insert(argv, tostring(param))
            end
        end
    end
end

function _callback(argv, opt)

    local madeargv = {}
    local has_command

    for i = 1, argv.n do
        local arg = argv[i] or " "
        if type(arg) == "table" then
            _append_params(madeargv, arg, i == argv.n)
        else
            local command = _append_command(madeargv, arg)
            if not has_command then
                has_command = command ~= "submodule"
            end
        end
    end

    if madeargv.repodir then
        table.insert(madeargv, 1, "-C")
        table.insert(madeargv, 2, path.absolute(madeargv.repodir))
        madeargv.repodir = nil
    end

    if has_command then
        local git = assert(find_tool("git"), "git not found!")
        os.vrunv(git.program, madeargv)
        return true
    end
end

function main(opt)
    return cli.build(_callback, nil)(opt)
end
