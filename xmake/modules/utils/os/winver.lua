--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        winver.lua
--

-- get windows version value from name
--
-- reference: https://msdn.microsoft.com/en-us/library/windows/desktop/aa383745(v=vs.85).aspx
--
function value(name)
    
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

-- get ntddi value from name 
function value_ntddi(name)
    
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
    local val = value(name)
    if val then
        val = val .. (subvalue or "0000")
    end
    return val
end

-- get windows system version
--
-- $ xmake l utils.os.winver
--
--   - win10: 10.0.14393
--   - xp:    5.1.2600
--
function main()

    -- get it from cache first
    if _g.winver ~= nil then
        return _g.winver 
    end

    -- get winver
    local winver = nil
    local verstr = try { function () return os.iorun("cmd /c ver") end }
    if verstr then
        winver = verstr:match("%[.-(%d+%.%d+%.%d+)]")
        if winver then
            winver = winver:trim()
        end
    end

    -- save to cache
    _g.winver = winver or false

    -- done
    return winver
end
