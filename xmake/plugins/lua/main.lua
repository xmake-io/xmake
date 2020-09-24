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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.sandbox.module")
import("core.sandbox.sandbox")

-- get all lua scripts
function scripts()
    local names = {}
    local files = os.files(path.join(os.scriptdir(), "scripts/*.lua"))
    for _, file in ipairs(files) do
        table.insert(names, path.basename(file))
    end
    return names
end

-- list all lua scripts
function _list()
    print("scripts:")
    for _, file in ipairs(scripts()) do
        print("    " .. file)
    end
end

-- print verbose log
function _print_vlog(script_type, script_name, args)
    if not option.get("verbose") then return end
    cprintf("running %s ${underline}%s${reset}", script_type, script_name)
    if args.n > 0 then
        print(" with args:")
        if not option.get("diagnosis") then
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

function _run_commanad(command, args)
    local tmpfile = os.tmpfile() .. ".lua"
    io.writefile(tmpfile, "function main(...)\n" .. command .. "\nend")
    return _run_script(tmpfile, args)
end

function _run_script(script, args)

    local func
    local printresult = false
    local script_type, script_name

    -- import and run script
    if path.extension(script) == ".lua" and os.isfile(script) then

        -- run the given lua script file (xmake lua /tmp/script.lua)
        script_type, script_name = "given lua script file", path.relative(script)
        func = import(path.basename(script), {rootdir = path.directory(script), anonymous = true})
    elseif os.isfile(path.join(os.scriptdir(), "scripts", script .. ".lua")) then

        -- run builtin lua script (xmake lua echo "hello xmake")
        script_type, script_name = "builtin lua script", script
        func = import("scripts." .. script, {anonymous = true})
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
    _print_vlog(script_type or "script", script_name or "", args)

    -- dump func() result
    if type(func) == "function" or (type(func) == "table" and func.main and type(func.main) == "function") then
        local result = table.pack(func(table.unpack(args, 1, args.n)))
        if printresult and result and result.n ~= 0 then
            utils.dump(unpack(result, 1, result.n))
        end
    else
        -- dump variables directly
        utils.dump(func)
    end
end

function _get_args()

    -- get arguments
    local args = option.get("arguments") or {}
    args.n = #args

    -- get deserialize tag
    local deserialize = option.get("deserialize")
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

function main()

    -- list builtin scripts
    if option.get("list") then
        return _list()
    end

    -- run command?
    local script = option.get("script")
    if option.get("command") and script then
        return _run_commanad(script, _get_args())
    end

    -- get script
    if script then
        return _run_script(script, _get_args())
    end

    -- enter interactive mode
    sandbox.interactive()
end
