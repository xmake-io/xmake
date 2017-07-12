--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("windows")

    -- set os
    set_os("windows")

    -- set hosts
    set_hosts("windows")

    -- set archs
    set_archs("x86", "x64")

    -- set environment
    set_environment("environment")

    -- on check
    on_check("check")

    -- on load
    on_load(function ()

        -- init the file formats
        _g.formats          = {}
        _g.formats.static   = {"", ".lib"}
        _g.formats.object   = {"", ".obj"}
        _g.formats.shared   = {"", ".dll"}
        _g.formats.binary   = {"", ".exe"}
        _g.formats.symbol   = {"", ".pdb"}

        -- init flags for dlang
        local dc_archs = { x86 = "-m32", x64 = "-m64" }
        _g.dcflags       = { dc_archs[arch] }
        _g["dc-shflags"] = { dc_archs[arch] }
        _g["dc-ldflags"] = { dc_archs[arch] }

        -- ok
        return _g
    end)

    -- set menu
    set_menu {
                config = 
                {   
                    {}   
                ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
                }

            ,   global = 
                {   
                    {}
                ,   {nil, "vs", "kv", "auto", "The Microsoft Visual Studio"   }
                }
            }


