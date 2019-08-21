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
-- @file        vstool.lua
--

-- quietly run command with arguments list
function runv(program, argv, opt)

    -- init options
    opt = opt or {}

    -- make temporary output and error file
    local outpath = os.tmpfile()
    local errpath = os.tmpfile()
    local outfile = io.open(outpath, 'w')

    -- enable unicode output for vs toolchains, e.g. cl.exe, link.exe and etc.
    -- @see https://github.com/xmake-io/xmake/issues/528
    local envs = {VS_UNICODE_OUTPUT = outfile:rawfd()}

    -- execute it
    local ok = os.execv(program, argv, table.join(opt, {try = true, stdout = outfile, stderr = errpath, envs = envs}))

    -- close outfile first
    outfile:close()

    -- failed?
    if ok ~= 0 then

        -- read errors
        local outdata = os.isfile(outpath) and io.readfile(outpath, {encoding = "utf16le"}) or nil
        local errdata = os.isfile(errpath) and io.readfile(errpath) or nil
        local errors = errdata or ""
        if #errors:trim() == 0 then
            errors = outdata or ""
        end

        -- make the default errors
        if not errors or #errors == 0 then
            if argv ~= nil then
                errors = string.format("vstool.runv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
            else
                errors = string.format("vstool.runv(%s) failed(%d)!", program, ok)
            end
        end

        -- remove the files
        os.tryrm(outpath)
        os.tryrm(errpath)

        -- raise errors
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
    end

    -- remove the files
    os.tryrm(outpath)
    os.tryrm(errpath)
end

-- run command and return output and error data
function iorunv(program, argv, opt)

    -- init options
    opt = opt or {}

    -- make temporary output and error file
    local outpath = os.tmpfile()
    local errpath = os.tmpfile()
    local outfile = io.open(outpath, 'w')

    -- enable unicode output for vs toolchains, e.g. cl.exe, link.exe and etc.
    -- @see https://github.com/xmake-io/xmake/issues/528
    local envs = {VS_UNICODE_OUTPUT = outfile:rawfd()}

    -- run command
    local ok = os.execv(program, argv, table.join(opt, {try = true, stdout = outfile, stderr = errpath, envs = envs}))

    -- get output and error data
    outfile:close()
    local outdata = os.isfile(outpath) and io.readfile(outpath, {encoding = "utf16le"}) or nil
    local errdata = os.isfile(errpath) and io.readfile(errpath) or nil

    -- remove the temporary output and error file
    os.tryrm(outpath)
    os.tryrm(errpath)

    -- failed?
    if ok ~= 0 then

        -- get errors
        local errors = errdata or ""
        if #errors:trim() == 0 then
            errors = outdata or ""
        end

        -- make the default errors
        if not errors or #errors == 0 then
            if argv ~= nil then
                errors = string.format("vstool.iorunv(%s %s) failed(%d)!", program, table.concat(argv, ' '), ok)
            else
                errors = string.format("vstool.iorunv(%s) failed(%d)!", program, ok)
            end
        end

        -- raise errors
        os.raise({errors = errors, stderr = errdata, stdout = outdata})
    end

    -- ok?
    return outdata, errdata
end

