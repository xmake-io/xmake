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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define task
task("lua")

    -- set category
    set_category("plugin")

    -- on run
    on_run(function ()
           
        -- imports
        import("core.base.option")
        import("core.sandbox.module")
        import("core.sandbox.sandbox")

        -- list all lua scripts?
        if option.get("list") then
            print("scripts:")
            local files = os.match(path.join(os.scriptdir(), "scripts/*.lua"))
            for _, file in ipairs(files) do
                print("    " .. path.basename(file))
            end
            return
        end

        -- run command?
        local script = option.get("script")
        if option.get("command") and script then
            local tmpfile = os.tmpfile() .. ".lua"
            io.writefile(tmpfile, "function main(...)\n" .. script .. "\nend")
            script = tmpfile
        end

        -- get script
        if script then

            -- import and run script
            if path.extension(script) == ".lua" and os.isfile(script) then

                -- run the given lua script file (xmake lua /tmp/script.lua)
                vprint("runing given lua script file: %s", path.relative(script))
                import(path.basename(script), {rootdir = path.directory(script), anonymous = true})(unpack(option.get("arguments") or {}))

            elseif os.isfile(path.join(os.scriptdir(), "scripts", script .. ".lua")) then

                -- run builtin lua script (xmake lua echo "hello xmake")
                vprint("runing builtin lua script: %s", script)
                import("scripts." .. script, {anonymous = true})(unpack(option.get("arguments") or {}))
            else

                -- attempt to find the builtin module
                local object = nil
                for _, name in ipairs(script:split("%.")) do
                    object = object and object[name] or module.get(name)
                    if not object then
                        break
                    end
                end
                local result = nil
                if object then
                    -- run builtin modules (xmake lua core.xxx.xxx)
                    vprint("runing builtin module: %s", script)
                    result = object(unpack(option.get("arguments") or {}))
                else
                    -- run imported modules (xmake lua core.xxx.xxx)
                    vprint("runing imported module: %s", script)
                    result = import(script, {anonymous = true})(unpack(option.get("arguments") or {}))
                end
                if result ~= nil then utils.dump(result) end
            end
        else
            -- enter interactive mode
            sandbox.interactive()
        end
    end)

    -- set menu
    set_menu {
                -- usage
                usage = "xmake lua|l [options] [script] [arguments]"

                -- description
            ,   description = "Run the lua script."

                -- xmake l
            ,   shortname = 'l'

                -- options
            ,   options = 
                {

                    {'l', "list",       "k",  nil,          "List all scripts."                              }
                ,   {'c', "command",    "k",  nil,          "Run script as command"                          }
                ,   {nil, "script",     "v",  nil,          "Run the given lua script name, file or module and enter interactive mode if no given script.",
                                                            "e.g.",
                                                            "    - xmake lua (enter interactive mode)",
                                                            "    - xmake lua /tmp/script.lua",
                                                            "    - xmake lua echo 'hello xmake'",
                                                            "    - xmake lua core.xxx.xxx",                   
                                                            "    - xmake lua -c 'print(...)' hello xmake!"   }
                ,   {nil, "arguments",  "vs", nil,          "The script arguments."                          }
                }
            }



