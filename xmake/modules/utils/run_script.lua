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
-- @file        run.lua
--

-- imports
import("core.base.option")
import("core.base.thread")
import("core.sandbox.module")

-- print verbose log
function _print_vlog(script_type, script_name, args, opt)
    if not opt.verbose then
        return
    end
    cprintf("running %s ${underline}%s${reset}", script_type, script_name)
    if args.n > 0 then
        print(" with args:")
        if not opt.diagnosis then
            for i = 1, args.n do
                print("  - " .. todisplay(args[i]))
            end
        else
            utils.dump(table.unpack(args, 1, args.n))
        end
    else
        print(".")
    end
end

function _is_callable(func)
    if type(func) == "function" then
        return true
    elseif type(func) == "table" then
        local meta = debug.getmetatable(func)
        if meta and meta.__call then
            return true
        end
    end
end

function _run_script(script, args, opt)

    local func
    local printresult = false
    local script_type, script_name

    -- import and run script
    if path.extension(script) == ".lua" and os.isfile(script) then

        -- run the given lua script file (xmake lua /tmp/script.lua)
        script_type, script_name = "given lua script file", path.relative(script)
        func = import(path.basename(script), {rootdir = path.directory(script), anonymous = true})
    elseif os.isfile(path.join(os.programdir(), "plugins", "lua", "scripts", script .. ".lua")) then

        -- run builtin lua script (xmake lua echo "hello xmake")
        script_type, script_name = "builtin lua script", script
        func = import("scripts." .. script, {anonymous = true, rootdir = path.join(os.programdir(), "plugins", "lua")})
    else

        -- attempt to find the builtin module
        local object = nil
        for _, name in ipairs(script:split("%.")) do
            object = object and object[name] or module.get(name)
            if not object then
                break
            end
        end
        if object then
            -- run builtin modules (xmake lua core.xxx.xxx)
            script_type, script_name = "builtin module", script
            func = object
        else
            -- run imported modules (xmake lua core.xxx.xxx)
            script_type, script_name = "imported module", script
            func = import(script, {anonymous = true})
        end
        printresult = true
    end

    -- print verbose log
    _print_vlog(script_type or "script", script_name or "", args, opt)

    -- dump func() result
    if _is_callable(func) then
        local result = table.pack(func(table.unpack(args, 1, args.n)))
        if printresult and result and result.n ~= 0 then
            utils.dump(table.unpack(result, 1, result.n))
        end
    else
        -- dump variables directly
        utils.dump(func)
    end
end

function _run_commanad(command, args, opt)
    local tmpfile = os.tmpfile() .. ".lua"
    io.writefile(tmpfile, "function main(...)\n" .. command .. "\nend")
    _run_script(tmpfile, args, opt)
end

function _get_args(opt)
    opt = opt or {}

    -- get arguments
    local args = opt.arguments or {}
    args.n = #args

    -- get deserialize tag
    local deserialize = opt.deserialize
    if not deserialize then
        return args
    end
    deserialize = tostring(deserialize)

    -- deserialize prefixed arguments
    for i, value in ipairs(args) do
        if value:startswith(deserialize) then
            local v, err = string.deserialize(value:sub(#deserialize + 1))
            if err then
                raise(err)
            else
                args[i] = v
            end
        end
    end
    return args
end

function _run(script, opt)
    opt = opt or {}

    if opt.quiet then
        option.save()
        option.set("quiet", true, {force = true})
    end

    local curdir = opt.curdir or os.workingdir()
    local oldir = os.cd(curdir)
    if opt.command then
        _run_commanad(script, _get_args(opt), opt)
    else
        _run_script(script, _get_args(opt), opt)
    end
    os.cd(oldir)

    if opt.quiet then
        option.restore()
    end
end

function _run_in_thread(script, opt)
    import("utils.run_script", {anonymous = true})(script, opt)
end

-- run lua script
--
-- @param script      the script file or string or module name
--                    e.g. /tmp/test.lua, "print("hello")", "utils.bin2c"
-- @param opt         the options
--                     - curdir      the currect directory
--                     - command     run script as command
--                     - deserialize deserialize arguments starts with given prefix
--                     - arguments   the script arguments
--                     - thread      run script in a new native thread
--                     - quiet       enable quiet output
--                     - verbose     enable verbose output
--                     - diagnosis   enable diagnosis output
function main(script, opt)
    opt = opt or {}
    if opt.thread then
        local argv
        for _, arg in ipairs(opt.arguments) do
            argv = argv or {}
            if path.instance_of(arg) then
                arg = tostring(arg)
            end
            table.insert(argv, arg)
        end
        local thread_opt = {
            curdir = curdir,
            command = opt.command,
            deserialize = opt.deserialize,
            arguments = argv,
            quiet = opt.quiet,
            verbose = opt.verbose,
            diagnosis = opt.diagnosis
        }
        local t = thread.start_named("utils.run_script", _run_in_thread, script, thread_opt)
        t:wait(-1)
    else
        _run(script, opt)
    end
end
