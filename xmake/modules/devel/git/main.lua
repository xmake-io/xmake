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

    local opt = argv.opt or {}
    argv.opt = opt

    for key, value in pairs(opts) do
        if type(value) == "table" then
            for _, v in ipairs(value) do
                _append_opt(argv, key, v)
            end
        else
            _append_opt(argv, key, value)
        end
        if type(opt[key]) == "table" then
            -- append for table
            table.join2(opt[key], value)
        else
            -- otherwise, overwrite
            opt[key] = value
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

local handlers = {
    ["ls-remote"] = function (out, err, opt)

        local reftype = "refs"
        if opt.tags then reftype = "tags" end
        if opt.heads then reftype = "heads" end

        -- get commmits and tags
        local refs = {}
        for _, line in ipairs(out:split('\n')) do

            -- parse commit and ref
            local refinfo = line:split('%s')

            -- get commit
            local commit = refinfo[1]

            -- get ref
            local ref = refinfo[2]

            -- save this ref
            local prefix = (reftype == "refs") and "refs/" or ("refs/" .. reftype .. "/")
            if ref and ref:startswith(prefix) and commit and #commit == 40 then
                table.insert(refs, ref:sub(#prefix + 1))
            end
        end

        -- ok
        return refs
    end
}

function _callback(argv, opt)

    local madeargv = {}
    local has_command
    local handler = handlers

    -- stop search builtin handlers
    if opt.handler == false then
        handler = nil
    end

    -- make argv, search handler
    for i = 1, argv.n do
        local arg = argv[i] or " "
        if type(arg) == "table" then
            _append_params(madeargv, arg, i == argv.n)
        else
            local command = _append_command(madeargv, arg)
            if not has_command then
                has_command = command ~= "submodule"
            end
            if handler then
                handler = handler[command]
            end
        end
    end

    -- not a command, continue builder
    if not has_command then
        return
    end

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- get handler
    local handlefunc = handler
    -- if opt.handler is a callable, use it instead of builtin handler
    if type(opt.handler) == "function" or type(opt.handler) == "table" then
        handlefunc = opt.handler
    end

    -- set repodir
    if madeargv.repodir then
        table.insert(madeargv, 1, "-C")
        table.insert(madeargv, 2, path.absolute(madeargv.repodir))
    end

    local verbose = option.get("verbose") or opt.verbose
    if verbose then
        print("%s %s", git.program, os.args(madeargv))
    end

    -- if opt.iorun is set, or a handler is available
    if opt.iorun or (handlefunc and opt.iorun ~= false) then
        local out, err = os.iorunv(git.program, madeargv)
        if handlefunc then
            return handlefunc(out, err, madeargv.opt or {})
        else
            return out, err
        end
    else
        (opt.verbose and os.execv or os.runv)(git.program, madeargv)
        return true
    end
end

function main(opt, build_opt)
    build_opt = build_opt or {}
    return cli.build(_callback, build_opt)(opt)
end
