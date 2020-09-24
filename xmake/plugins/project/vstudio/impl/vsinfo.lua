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
-- @file        vsinfo.lua
--

local vsinfo =
{
    [2002] =
    {   vstudio_version     = "2002"
    ,   solution_version    = "7"
    ,   project_version     = "7.0"
    }
,   [2003] =
    {   vstudio_version     = "2003"
    ,   solution_version    = "8"
    ,   project_version     = "7.1"
    }
,   [2005] =
    {   vstudio_version     = "2005"
    ,   solution_version    = "9"
    ,   project_version     = "8.0"
    }
,   [2008] =
    {   vstudio_version     = "2008"
    ,   solution_version    = "10"
    ,   project_version     = "9.0"
    }
,   [2010] =
    {   vstudio_version     = "2010"
    ,   project_version     = "4"
    ,   filters_version     = "4.0"
    ,   solution_version    = "11"
    ,   toolset_version     = "v100"
    }
,   [2012] =
    {   vstudio_version     = "2012"
    ,   project_version     = "4"
    ,   filters_version     = "4.0"
    ,   solution_version    = "12"
    ,   toolset_version     = "v110"
    }
,   [2013] =
    {   vstudio_version     = "2013"
    ,   project_version     = "12"
    ,   filters_version     = "4.0"
    ,   solution_version    = "12"
    ,   toolset_version     = "v120"
    }
,   [2015] =
    {   vstudio_version     = "2015"
    ,   project_version     = "14"
    ,   filters_version     = "4.0"
    ,   solution_version    = "12"
    ,   toolset_version     = "v140"
    ,   sdk_version         = "10.0.10240.0"
    }
,   [2017] =
    {   vstudio_version     = "2017"
    ,   project_version     = "15"
    ,   filters_version     = "4.0"
    ,   solution_version    = "12"
    ,   toolset_version     = "v141"
    ,   sdk_version         = "10.0.14393.0"
    }
,   [2019] =
    {   vstudio_version     = "2019"
    ,   project_version     = "16"
    ,   filters_version     = "4.0"
    ,   solution_version    = "12"
    ,   toolset_version     = "v142"
    ,   sdk_version         = "10.0.17763.0"
    }
}

function main(version)
    assert(version)
    return assert(vsinfo[version], "unsupported vs version (%d)", version);
end