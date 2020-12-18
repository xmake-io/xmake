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
-- @file        winver.lua
--

-- get WINVER from name
--
-- reference: https://msdn.microsoft.com/en-us/library/windows/desktop/aa383745(v=vs.85).aspx
--
function version(name)

    -- init values
    _g.values = _g.values or
    {
        nt4      = "0x0400"
    ,   win2k    = "0x0500"
    ,   winxp    = "0x0501"
    ,   ws03     = "0x0502"
    ,   win6     = "0x0600"
    ,   vista    = "0x0600"
    ,   ws08     = "0x0600"
    ,   longhorn = "0x0600"
    ,   win7     = "0x0601"
    ,   win8     = "0x0602"
    ,   winblue  = "0x0603"
    ,   win81    = "0x0603"
    ,   win10    = "0x0A00"
    }

    -- ignore the subname with '_xxx'
    name = name:split('_')[1]

    -- get value
    return _g.values[name]
end

-- get NTDDI_VERSION from name
function ntddi_version(name)

    -- init subvalues
    _g.subvalues = _g.subvalues or
    {
        sp1    = "0100"
    ,   sp2    = "0200"
    ,   sp3    = "0300"
    ,   sp4    = "0400"
    ,   th2    = "0001"
    ,   rs1    = "0002"
    ,   rs2    = "0003"
    ,   rs3    = "0004"
    }

    -- get subvalue
    local subvalue = nil
    local subname = name:split('_')[2]
    if subname then
        subvalue = _g.subvalues[subname]
    end

    -- get value
    local val = version(name)
    if val then
        val = val .. (subvalue or "0000")
    end
    return val
end

-- get _WIN32_WINNT from name
function winnt_version(name)
    return version(name)
end

-- get _NT_TARGET_VERSION from name
function target_version(name)
    return version(name)
end

-- get subsystem version from name
function subsystem(name)

    -- ignore the subname with '_xxx'
    name = (name or ""):split('_')[1]

    -- make defined values
    local defvals =
    {
        nt4      = "4.00"
    ,   win2k    = "5.00"
    ,   winxp    = "5.01"
    ,   ws03     = "5.02"
    ,   win6     = "6.00"
    ,   vista    = "6.00"
    ,   ws08     = "6.00"
    ,   longhorn = "6.00"
    ,   win7     = "6.01"
    ,   win8     = "6.02"
    ,   winblue  = "6.03"
    ,   win81    = "6.03"
    ,   win10    = "10.00"
    }
    return defvals[name] or "10.00"
end
