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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.cache.localcache")

-- the macro directories
function _directories()

    return {    path.join(config.directory(), "macros")
            ,   path.join(os.scriptdir(), "macros")}
end

-- the macro directory
function _directory(macroname)

    -- find macro directory
    local macrodir = nil
    for _, dir in ipairs(_directories()) do

        -- found?
        if os.isfile(path.join(dir, macroname .. ".lua")) then
            macrodir = dir
            break
        end
    end

    -- check
    assert(macrodir, "macro(%s) not found!", macroname)
    return macrodir
end

-- the readable macro file
function _rfile(macroname)
    if macroname == '.' then
        macroname = "anonymous"
    end
    return path.join(_directory(macroname), macroname .. ".lua")
end

-- the writable macro file
function _wfile(macroname)
    if macroname == '.' then
        macroname = "anonymous"
    end
    return path.join(path.join(config.directory(), "macros"), macroname .. ".lua")
end

-- get all macros
function macros(anonymousname)

    local results = {}
    -- find all macros
    for _, dir in ipairs(_directories()) do
        local macrofiles = os.match(path.join(dir, "*.lua"))
        for _, macrofile in ipairs(macrofiles) do

            -- get macro name
            local macroname = path.basename(macrofile)
            if macroname == "anonymous" and anonymousname then
                macroname = anonymousname
            end
            table.insert(results, macroname)
        end
    end
    return results
end

-- list macros
function _list()
    cprint("${bright}macros:")
    for _, macroname in ipairs(macros(".<anonymous>")) do
        print("    " .. macroname)
    end
end

-- show macro
function _show(macroname)
    local file = _rfile(macroname)
    if os.isfile(file) then
        io.cat(file)
    else
        raise("macro(%s) not found!", macroname)
    end
end

-- clear all macros
function _clear()
    os.rm(path.join(config.directory(), "macros"))
end

-- delete macro
function _delete(macroname)

    -- remove it
    if os.isfile(_wfile(macroname)) then
        os.rm(_wfile(macroname))
    elseif os.isfile(_rfile(macroname)) then
        raise("macro(%s) cannot be deleted!", macroname)
    else
        raise("macro(%s) not found!", macroname)
    end

    -- trace
    cprint("${color.success}delete macro(%s) ok!", macroname)
end

-- import macro
function _import(macrofile, macroname)

    -- import all macros
    if os.isdir(macrofile) then

        -- the macro directory
        local macrodir = macrofile
        local macrofiles = os.match(path.join(macrodir, "*.lua"))
        for _, macrofile in ipairs(macrofiles) do

            -- the macro name
            macroname = path.basename(macrofile)

            -- import it
            os.cp(macrofile, _wfile(macroname))

            -- trace
            cprint("${color.success}import macro(%s) ok!", macroname)
        end
    else

        -- import it
        os.cp(macrofile, _wfile(macroname))

        -- trace
        cprint("${color.success}import macro(%s) ok!", macroname)
    end
end

-- export macro
function _export(macrofile, macroname)

    -- export all macros
    if os.isdir(macrofile) then

        -- the output directory
        local outputdir = macrofile

        -- export all macros
        for _, dir in ipairs(_directories()) do
            local macrofiles = os.match(path.join(dir, "*.lua"))
            for _, macrofile in ipairs(macrofiles) do

                -- export it
                os.cp(macrofile, outputdir)

                -- trace
                cprint("${color.success}export macro(%s) ok!", path.basename(macrofile))
            end
        end
    else
        -- export it
        os.cp(_rfile(macroname), macrofile)

        -- trace
        cprint("${color.success}export macro(%s) ok!", macroname)
    end
end

-- begin to record macro
function _begin()
    localcache.set("history", "cmdlines", "__macro_begin__")
    localcache.save("history")
end

-- end to record macro
function _end(macroname)

    -- load the history: cmdlines
    local cmdlines = table.wrap(localcache.get("history", "cmdlines"))

    -- get the last macro block
    local begin = false
    local block = {}
    local total = #cmdlines
    local index = total
    while index ~= 0 do

        -- the command line
        local cmdline = cmdlines[index]

        -- found begin? break it
        if cmdline == "__macro_begin__" then
            begin = true
            break
        end

        -- found end? break it
        if cmdline == "__macro_end__" then
            break
        end

        -- ignore "xmake m .." and "xmake macro .."
        if not cmdline:find("xmake%s+macro%s*") and not cmdline:find("xmake%s+m%s*") then

            -- save this command line to block
            table.insert(block, 1, cmdline)
        end

        -- the previous line
        index = index - 1
    end

    -- the begin tag not found?
    if not begin then
        raise("please run: 'xmake macro --begin' first!")
    end

    -- patch end tag to the history: cmdlines
    table.insert(cmdlines, "__macro_end__")
    localcache.set("history", "cmdlines", cmdlines)
    localcache.save("history")

    -- open the macro file
    local file = io.open(_wfile(macroname), "w")

    -- save the macro begin
    file:print("function main(argv)")

    -- save the macro block
    for _, cmdline in ipairs(block) do
        file:print("    os.exec(\"%s\")", (cmdline:gsub("[\\\"]", function (w) return "\\" .. w end)))
    end

    -- save the macro end
    file:print("end")

    -- exit the macro file
    file:close()

    -- show this macro
    _show(macroname)

    -- trace
    cprint("${color.success}define macro(%s) ok!", macroname)
end

-- run macro
function _run(macroname)

    -- run last command?
    if macroname == ".." then

        -- load the history: cmdlines
        local cmdlines = localcache.get("history", "cmdlines")

        -- get the last command
        local lastcmd = nil
        if cmdlines then
            local total = #cmdlines
            local index = total
            while index ~= 0 do

                -- ignore "xmake m .." and "xmake macro .."
                local cmdline = cmdlines[index]
                if not cmdline:startswith("__macro_") and not cmdline:find("xmake%s+macro%s*") and not cmdline:find("xmake%s+m%s*") then
                    lastcmd = cmdline
                    break
                end

                -- the previous line
                index = index - 1
            end
        end

        -- run the last command
        if lastcmd then
            os.exec(lastcmd)
        end
        return
    end

    -- is anonymous?
    if macroname == '.' then
        macroname = "anonymous"
    end

    -- run macro
    import(macroname, {rootdir = _directory(macroname), anonymous = true})(option.get("arguments") or {})
end

-- main
function main()

    -- list macros
    if option.get("list") then

        _list()

    -- show macro
    elseif option.get("show") then

        _show(option.get("name"))

    -- clear macro
    elseif option.get("clear") then

        _clear()

    -- delete macro
    elseif option.get("delete") then

        _delete(option.get("name"))

    -- import macro
    elseif option.get("import") then

        _import(option.get("import"), option.get("name"))

    -- export macro
    elseif option.get("export") then

        _export(option.get("export"), option.get("name"))

    -- begin to record macro
    elseif option.get("begin") then

        _begin()

    -- end to record macro
    elseif option.get("end") then

        _end(option.get("name"))

    -- run macro
    else
        _run(option.get("name"))
    end
end
