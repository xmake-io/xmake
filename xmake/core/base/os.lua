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
-- @file        os.lua
--

-- define module
local os = os or {}

-- load modules
local io        = require("base/io")
local log       = require("base/log")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- save original interfaces
os._uid         = os._uid or os.uid
os._gid         = os._gid or os.gid
os._mkdir       = os._mkdir or os.mkdir
os._rmdir       = os._rmdir or os.rmdir
os._tmpdir      = os._tmpdir or os.tmpdir
os._setenv      = os._setenv or os.setenv
os._getenvs     = os._getenvs or os.getenvs
os._readlink    = os._readlink or os.readlink

-- copy single file or directory 
function os._cp(src, dst)
    
    -- check
    assert(src and dst)

    -- is file?
    if os.isfile(src) then
        
        -- the destination is directory? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            dst = path.join(dst, path.filename(src))
        end

        -- copy file
        if not os.cpfile(src, dst) then
            return false, string.format("cannot copy file %s to %s, error: %s", src, dst, os.strerror())
        end
    -- is directory?
    elseif os.isdir(src) then
        
        -- the destination directory exists? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- copy directory
        if not os.cpdir(src, dst) then
            return false, string.format("cannot copy directory %s to %s, error:  %s", src, dst, os.strerror())
        end

    -- not exists?
    else
        return false, string.format("cannot copy file %s, error: not found this file", src)
    end
    
    -- ok
    return true
end

-- move single file or directory
function os._mv(src, dst)
    
    -- check
    assert(src and dst)

    -- exists file or directory?
    if os.exists(src) then
 
        -- the destination directory exists? append the filename
        if os.isdir(dst) or path.islastsep(dst) then
            dst = path.join(dst, path.filename(path.translate(src)))
        end

        -- move file or directory
        if not os.rename(src, dst) then
            return false, string.format("cannot move %s to %s %s", src, dst, os.strerror())
        end
    -- not exists?
    else
        return false, string.format("cannot move %s to %s, not found this file %s", src, dst, os.strerror())
    end
    
    -- ok
    return true
end

-- remove single file or directory 
function os._rm(filedir)
    
    -- check
    assert(filedir)

    -- is file or link?
    if os.isfile(filedir) or os.islink(filedir) then
        -- remove file
        if not os.rmfile(filedir) then
            return false, string.format("cannot remove file %s %s", filedir, os.strerror())
        end
    -- is directory?
    elseif os.isdir(filedir) then
        -- remove directory
        if not os.rmdir(filedir) then
            return false, string.format("cannot remove directory %s %s", filedir, os.strerror())
        end
    end

    -- ok
    return true
end

-- translate arguments for wildcard
function os.argw(argv)

    -- match all arguments
    local results = {}
    for _, arg in ipairs(table.wrap(argv)) do
        
        -- exists wildcards?
        if arg:find("([%+%-%^%$%*%[%]%%])") then
            local pathes = os.match(arg, 'a')
            if #pathes > 0 then
                table.join2(results, pathes)
            else
                table.insert(results, arg)
            end
        else
            table.insert(results, arg)
        end
    end

    -- ok?
    return results
end

-- make string from arguments list
function os.args(argv)

    -- make it
    local args = nil
    for _, arg in ipairs(table.wrap(argv)) do
        arg = arg:trim()
        if #arg > 0 then
            arg = arg:gsub("([\"\\])", "\\%1")
            if arg:find("%s") then
                if args then
                    args = args .. " \"" .. arg .. "\""
                else
                    args = "\"" .. arg .. "\""
                end
            else
                if args then
                    args = args .. " " .. arg
                else
                    args = arg
                end
            end
        end
    end

    -- ok?
    return args or ""
end

-- match files or directories
--
-- @param pattern   the search pattern 
--                  uses "*" to match any part of a file or directory name,
--                  uses "**" to recurse into subdirectories.
--
-- @param mode      the match mode
--                  - only find file:           'f' or false or nil
--                  - only find directory:      'd' or true
--                  - find file and directory:  'a'
-- @return          the result array and count
--
-- @code
-- local dirs, count = os.match("./src/*", true)
-- local files, count = os.match("./src/**.c")
-- local file = os.match("./src/test.c", 'f', function (filepath, isdir) 
--                  return true   -- continue it
--                  return false  -- break it
--              end)
-- @endcode
--
function os.match(pattern, mode, callback)

    -- get the excludes
    local excludes = pattern:match("|.*$")
    if excludes then excludes = excludes:split("|") end

    -- translate excludes
    if excludes then
        local _excludes = {}
        for _, exclude in ipairs(excludes) do
            exclude = path.translate(exclude)
            exclude = exclude:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
            exclude = exclude:gsub("%*%*", "\001")
            exclude = exclude:gsub("%*", "\002")
            exclude = exclude:gsub("\001", ".*")
            exclude = exclude:gsub("\002", "[^/]*")
            table.insert(_excludes, exclude)
        end
        excludes = _excludes
    end

    -- translate path and remove some repeat separators
    pattern = path.translate(pattern:gsub("|.*$", ""))

    -- translate mode
    if type(mode) == "string" then
        local modes = {a = -1, f = 0, d = 1}
        mode = modes[mode]
        assert(mode, "invalid match mode: %s", mode)
    elseif mode then
        mode = 1
    else 
        mode = 0
    end

    -- match the single file without wildchard?
    if os.isfile(pattern) then
        if mode <= 0 then
            return {pattern}, 1
        else
            return {}, 0
        end
    -- match the single directory without wildchard?
    elseif os.isdir(pattern) then
        if (mode == -1 or mode == 1) then
            return {pattern}, 1
        else
            return {}, 0
        end
    end

    -- remove "./" or '.\\' prefix
    if pattern:sub(1, 2):find('%.[/\\]') then
        pattern = pattern:sub(3)
    end

    -- get the root directory
    local rootdir = pattern
    local startpos = pattern:find("*", 1, true)
    if startpos then
        rootdir = rootdir:sub(1, startpos - 1)
    end
    rootdir = path.directory(rootdir)

    -- compute the recursion level
    --
    -- infinite recursion: src/**.c
    -- limit recursion level: src/*/*.c
    local recursion = 0
    if pattern:find("**", 1, true) then
        recursion = -1
    else
        -- "src/*/*.c" -> "*/" -> recursion level: 1
        -- "src/*/main.c" -> "*/" -> recursion level: 1
        -- "src/*/subdir/main.c" -> "*//" -> recursion level: 2
        if startpos then
            local _, seps = pattern:sub(startpos):gsub("[/\\]", "")
            if seps > 0 then
                recursion = seps
            end
        end
    end

    -- convert pattern to a lua pattern
    pattern = path.pattern(pattern)

    -- find it
    return os.find(rootdir, pattern, recursion, mode, excludes, callback)
end

-- match directories
--
-- @note only return {} without count to simplify code, .e.g unpack(os.dirs(""))
--
function os.dirs(pattern, callback)
    return (os.match(pattern, 'd', callback))
end

-- match files
function os.files(pattern, callback)
    return (os.match(pattern, 'f', callback))
end

-- match files and directories
function os.filedirs(pattern, callback)
    return (os.match(pattern, 'a', callback))
end

-- copy files or directories
function os.cp(...)
   
    -- check arguments
    local args = {...}
    if #args < 2 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- get source pathes
    local srcpathes = table.slice(args, 1, #args - 1)

    -- get destinate path
    local dstpath = args[#args]

    -- copy files or directories
    for _, srcpath in ipairs(os.argw(srcpathes)) do
        local ok, errors = os._cp(srcpath, dstpath)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- move files or directories
function os.mv(...)
   
    -- check arguments
    local args = {...}
    if #args < 2 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- get source pathes
    local srcpathes = table.slice(args, 1, #args - 1)

    -- get destinate path
    local dstpath = args[#args]

    -- move files or directories
    for _, srcpath in ipairs(os.argw(srcpathes)) do
        local ok, errors = os._mv(srcpath, dstpath)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- remove files or directories
function os.rm(...)
    
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- remove directories
    for _, filedir in ipairs(os.argw(args)) do
        if not os._rm(filedir) then
            return false, string.format("remove: %s failed!", filedir)
        end
    end

    -- ok
    return true
end

-- link file or directory to the new symfile
function os.ln(filedir, symfile)
    if os.host() == "windows" then
        return false, string.format("symlink is not supported!")
    end
    if not os.link(filedir, symfile) then
        return false, string.format("link %s to %s failed!", filedir, symfile)
    end
    return true
end

-- change to directory
function os.cd(dir)

    -- check
    assert(dir)

    -- the previous directory
    local oldir = os.curdir()

    -- change to the previous directory?
    if dir == "-" then
        -- exists the previous directory?
        if os._PREDIR then
            dir = os._PREDIR
            os._PREDIR = nil
        else
            -- error
            return nil, string.format("not found the previous directory %s", os.strerror())
        end
    end

    -- is directory?
    if os.isdir(dir) then

        -- change to directory
        if not os.chdir(dir) then
            return nil, string.format("cannot change directory %s %s", dir, os.strerror())
        end

        -- save the previous directory
        os._PREDIR = oldir

    -- not exists?
    else
        return nil, string.format("cannot change directory %s, not found this directory %s", dir, os.strerror())
    end
    
    -- ok
    return oldir
end

-- create directories
function os.mkdir(...)
   
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- create directories
    for _, dir in ipairs(os.argw(args)) do
        if not os._mkdir(dir) then
            return false, string.format("create directory: %s failed!", dir)
        end
    end

    -- ok
    return true
end

-- remove directories
function os.rmdir(...)
   
    -- check arguments
    local args = {...}
    if #args < 1 then
        return false, string.format("invalid arguments: %s", table.concat(args, ' '))
    end

    -- create directories
    for _, dir in ipairs(os.argw(args)) do
        if not os._rmdir(dir) then
            return false, string.format("remove directory: %s failed!", dir)
        end
    end

    -- ok
    return true
end

-- get the temporary directory
function os.tmpdir()

    -- is in fakeroot? @note: uid always be 0 in root and fakeroot
    if os._FAKEROOT == nil then
        local ldpath = os.getenv("LD_LIBRARY_PATH")
        if ldpath and ldpath:find("libfakeroot", 1, true) then
            os._FAKEROOT = true
        else
            os._FAKEROOT = false
        end
    end

    -- get root tmpdir
    if os._ROOT_TMPDIR == nil then
        os._ROOT_TMPDIR = os.getenv("XMAKE_TMPDIR") or os._tmpdir()
    end
    local tmpdir_root = os._ROOT_TMPDIR

    -- make sub-directory name
    local subdir = (os._FAKEROOT and ".xmakefake" or ".xmake") .. (os.uid().euid or "")

    -- get a temporary directory for each user
    local tmpdir = path.join(tmpdir_root, subdir, os.date("%y%m%d"))

    -- ensure this directory exist and remove the previous directory
    if not os.isdir(tmpdir) then
        os.mkdir(tmpdir)
    end
    return tmpdir
end

-- generate the temporary file path
function os.tmpfile(key)
    return path.join(os.tmpdir(), "_" .. (hash.uuid(key):gsub("-", "")))
end

-- run command
function os.run(cmd)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return false, string.format("invalid command: %s", cmd)
    end

    -- run it
    return os.runv(argv[1], table.slice(argv, 2))
end

-- run command with arguments list
function os.runv(program, argv, opt)

    -- make temporary log file
    local log = os.tmpfile()

    -- execute it
    local ok = os.execv(program, argv, table.join(opt or {}, {stdout = log, stderr = log}))
    if ok ~= 0 then

        -- make errors
        local errors = io.readfile(log)
        if not errors or #errors == 0 then
            if argv ~= nil then
                errors = string.format("runv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
            else
                errors = string.format("runv(%s) failed(%d)!", program, ok)
            end
        end

        -- remove the temporary log file
        os.rm(log)

        -- failed
        return false, errors
    end

    -- remove the temporary log file
    os.rm(log)

    -- ok
    return true
end

-- execute command 
function os.exec(cmd, outfile, errfile)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return -1
    end

    -- run it
    return os.execv(argv[1], table.slice(argv, 2), {stdout = outfile, stderr = errfile})
end

-- execute command with arguments list
--
-- @param program     "clang", "xcrun -sdk macosx clang", "~/dir/test\ xxx/clang"
--        filename    "clang", "xcrun"", "~/dir/test\ xxx/clang"
-- @param argv        the arguments 
-- @param opt         the options, .e.g {wildcards = false, stdout = outfile, stderr = errfile, 
--                                       envs = {PATH = "xxx;xx", CFLAGS = "xx"}}
--
function os.execv(program, argv, opt)

    -- init options
    opt = opt or {}

    -- enable wildcards? default enabled
    local wildcards = opt.wildcards
    if wildcards == nil then
        wildcards = true
    end

    -- translate arguments for wildcards
    argv = wildcards and os.argw(argv) or argv

    -- is not executable program file?
    local filename = program
    if not os.isexec(program) then

        -- parse the filename and arguments, .e.g "xcrun -sdk macosx clang"
        local splitinfo = program:split("%s")
        filename = splitinfo[1]
        if #splitinfo > 1 then
            argv = table.join(table.slice(splitinfo, 2), argv)
        end
    end

    -- uses the given environments?
    local envs = nil
    if opt.envs then
        local envars = os.getenvs()
        for k, v in pairs(opt.envs) do
            envars[k] = v
        end
        envs = {}
        for k, v in pairs(envars) do
            table.insert(envs, k .. '=' .. v)
        end
    end

    -- open command
    local ok = -1
    local proc = process.openv(filename, argv, opt.stdout, opt.stderr, envs)
    if proc ~= nil then

        -- wait process
        local waitok = -1
        local status = -1 
        if coroutine.running() then

            -- save the current directory
            local curdir = os.curdir()

            -- wait it
            repeat
                -- poll it
                waitok, status = process.wait(proc, 0)
                if waitok == 0 then
                    waitok, status = coroutine.yield(proc)
                end
            until waitok ~= 0

            -- resume the current directory
            os.cd(curdir)
        else
            waitok, status = process.wait(proc, -1)
        end

        -- get status
        if waitok > 0 then
            ok = status
        end

        -- close process
        process.close(proc)
    end

    -- ok?
    return ok
end

-- run command and return output and error data
function os.iorun(cmd)

    -- parse arguments
    local argv = os.argv(cmd)
    if not argv or #argv <= 0 then
        return false, string.format("invalid command: %s", cmd)
    end

    -- run it
    return os.iorunv(argv[1], table.slice(argv, 2))
end

-- run command with arguments and return output and error data
function os.iorunv(program, argv, opt)

    -- make temporary output and error file
    local outfile = os.tmpfile()
    local errfile = os.tmpfile()

    -- run command
    local ok = os.execv(program, argv, table.join(opt or {}, {stdout = outfile, stderr = errfile})) 

    -- get output and error data
    local outdata = io.readfile(outfile)
    local errdata = io.readfile(errfile)

    -- remove the temporary output and error file
    os.rm(outfile)
    os.rm(errfile)

    -- ok?
    return ok == 0, outdata, errdata
end

-- raise an exception and abort the current script
--
-- the parent function will capture it if we uses pcall or xpcall
--
function os.raise(msg, ...)

    -- flush log
    log:flush()

    -- flush io buffer 
    io.flush()

    -- raise it
    if type(msg) == "string" then
        error(string.tryformat(msg, ...))
    elseif type(msg) == "table" then
        local errobjstr, errors = string.serialize(msg, true)
        if errobjstr then
            error("[@encode(error)]: " .. errobjstr)
        else
            error(errors)
        end
    else
        error()
    end
end

-- is executable program file?
function os.isexec(filepath)

    -- check
    assert(filepath)

    -- TODO
    -- check permission

    -- is *.exe for windows?
    if os.host() == "windows" then
        if not filepath:endswith(".exe") and not filepath:endswith(".cmd") and not filepath:endswith(".bat") then
            filepath = filepath .. ".exe"
        end
    end

    -- file exists?
    return os.isfile(filepath)
end

-- get the system host
function os.host()
    return xmake._HOST
end

-- get the system architecture
function os.arch()
    return xmake._ARCH
end

-- the current host is belong to the given hosts?
function os.is_host(...)

    -- get the current host
    local host = os.host()
    if not host then return false end

    -- exists this host? and escape '-'
    for _, h in ipairs(table.join(...)) do
        if h and type(h) == "string" and host:find(h:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function os.is_arch(...)

    -- get the host architecture
    local arch = os.arch()
    if not arch then return false end

    -- exists this architecture? and escape '-'
    for _, a in ipairs(table.join(...)) do
        if a and type(a) == "string" and arch:find("^" .. a:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get the system null device 
function os.nuldev(input)

    if input then
        if os.host() == "windows" then
            -- init the input nuldev
            if xmake._NULDEV_INPUT == nil then
                -- create an empty file
                --
                -- for fix issue on mingw:
                -- $ gcc -fopenmp -S -o nul -xc nul
                -- gcc: fatal error：input file 'nul' is the same as output file
                --
                local inputfile = os.tmpfile()
                io.writefile(inputfile, "")
                xmake._NULDEV_INPUT = inputfile
            end
        else
            if xmake._NULDEV_INPUT == nil then
                xmake._NULDEV_INPUT = "/dev/null"
            end
        end
        return xmake._NULDEV_INPUT
    else
        if os.host() == "windows" then
            -- @note cannot cache this file path to avoid multi-processes writing to the same file at the same time
            return os.tmpfile()
        else
            if xmake._NULDEV_OUTPUT == nil then
                xmake._NULDEV_OUTPUT = "/dev/null"
            end
            return xmake._NULDEV_OUTPUT
        end
    end
end

-- get user agent
function os.user_agent()

    -- init user agent
    if os._USER_AGENT == nil then
        
        -- init systems
        local systems = {macosx = "Macintosh", linux = "Linux", windows = "Windows"}

        -- os user agent
        local os_user_agent = ""
        if os.host() == "macosx" then
            local ok, osver = os.iorun("/usr/bin/sw_vers -productVersion")
            if ok then
                os_user_agent = ("Intel Mac OS X " .. (osver or "")):trim()
            end
        elseif os.host() == "linux" then
            local ok, osarch = os.iorun("uname -m")
            if ok then
                os_user_agent = (os_user_agent .. " " .. (osarch or "")):trim()
            end
            ok, osver = os.iorun("uname -r")
            if ok then
                os_user_agent = (os_user_agent .. " " .. (osver or "")):trim()
            end
        end

        -- make user agent
        os._USER_AGENT = string.format("Xmake/%s (%s;%s)", xmake._VERSION_SHORT, systems[os.host()] or os.host(), os_user_agent)
    end

    -- ok?
    return os._USER_AGENT
end

-- get uid
function os.uid(...)
    -- get uid
    os._UID = {}
    if os._uid then
        os._UID = os._uid(...) or {}
    end

    -- ok?
    return os._UID
end

-- get gid
function os.gid(...)
    -- get gid
    os._GID = {}
    if os._gid then
        os._GID = os._gid(...) or {}
    end

    -- ok?
    return os._GID
end

-- check the current command is running as root
function os.isroot()

    -- check it
    return os.uid().euid == 0
end

-- is case-insensitive filesystem?
function os.fscase()
    if os._FSCASE == nil then
        if os.host() == "windows" then
            os._FSCASE = false
        else

            -- get temporary directory
            local tmpdir = os.tmpdir()

            -- get matching pattern, this is equal to os.filedirs(path.join(tmpdir, "*"))
            --
            -- @note we cannot use os.match() becase os.fscase() will be called in os.match()
            --
            local pattern = path.join(tmpdir, "*")
            pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
            pattern = pattern:gsub("%*", "\002")
            pattern = pattern:gsub("\002", "[^/]*")

            -- attempt to detect it
            local file = os.find(tmpdir, pattern, 0, -1, nil, function (file, isdir) return false end)
            if file and #file > 0 then
                local file1 = file[1]
                local file2 = file1:gsub(".",  function (ch) return (ch >= 'a' and ch <= 'z') and ch:upper() or ch:lower() end)
                os._FSCASE = not (os.exists(file1) and os.exists(file2))
            else
                os._FSCASE = true
            end
        end
    end
    return os._FSCASE
end

-- get all current environment variables
function os.getenvs()
    local envs = {}
    for _, line in ipairs(os._getenvs()) do
        local p = line:find('=', 1, true)
        if p then
            local key = line:sub(1, p - 1):trim()
            if os.host() == "windows" then
                key = key:upper()
            end
            local values = line:sub(p + 1):trim()
            if #key > 0 then
                envs[key] = values
            end
        end
    end
    return envs
end

-- set values to environment variable 
function os.setenv(name, ...)
    return os._setenv(name, table.concat({...}, path.envsep()))
end

-- add values to environment variable 
function os.addenv(name, ...)
    local sep = path.envsep()
    local values = {...}
    if #values > 0 then
        return os._setenv(name, table.concat(values, sep) .. sep ..  (os.getenv(name) or ""))
    else
        return true
    end
end

-- set values to environment variable with the given seperator 
function os.setenvp(name, values, sep)
    sep = sep or path.envsep()
    return os._setenv(name, table.concat(table.wrap(values), sep))
end

-- add values to environment variable with the given seperator 
function os.addenvp(name, values, sep)
    sep = sep or path.envsep()
    values = table.wrap(values)
    if #values > 0 then
        return os._setenv(name, table.concat(values, sep) .. sep ..  (os.getenv(name) or ""))
    else
        return true
    end
end

-- read string data from pasteboard
function os.pbpaste()
    if os.host() == "macosx" then
        local ok, result = os.iorun("pbpaste")
        if ok then
            return result
        end
    elseif os.host() == "linux" then
        local ok, result = os.iorun("xsel --clipboard --output")
        if ok then
            return result
        end
    else
        -- TODO
    end
end

-- copy string data to pasteboard
function os.pbcopy(data)
    if os.host() == "macosx" then
        os.run("bash -c \"echo '" .. data .. "' | pbcopy\"")
    elseif os.host() == "linux" then
        os.run("bash -c \"echo '" .. data .. "' | xsel --clipboard --input\"")
    else
        -- TODO
    end
end

-- read the content of symlink
function os.readlink(symlink)
    return os._readlink(path.absolute(symlink))
end

-- get the program directory
function os.programdir()
    return xmake._PROGRAM_DIR
end

-- get the program file
function os.programfile()
    return xmake._PROGRAM_FILE
end

-- get the working directory
function os.workingdir()
    return xmake._WORKING_DIR
end

-- get the project directory
function os.projectdir()
    return xmake._PROJECT_DIR
end

-- get the project file
function os.projectfile()
    return xmake._PROJECT_FILE
end

-- return module
return os
