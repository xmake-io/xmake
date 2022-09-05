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
-- @author      WubiCookie
-- @file        find_matlab_runtime.lua
--

-- see https://www.mathworks.com/products/compiler/matlab-runtime.html
local matlabvers = {
    ["9.12"]  = "R2022a"
,   ["9.11"]  = "R2021b"
,   ["9.10"]  = "R2021a"
,   ["9.9"]   = "R2020b"
,   ["9.8"]   = "R2020a"
,   ["9.7"]   = "R2019b"
,   ["9.6"]   = "R2019a"
,   ["9.5"]   = "R2018b"
,   ["9.4"]   = "R2018a"
,   ["9.3"]   = "R2017b"
,   ["9.2"]   = "R2017a"
,   ["9.1"]   = "R2016b"
,   ["9.0.1"] = "R2016a"
,   ["9.0"]   = "R2015b"
,   ["8.5.1"] = "R2015aSP1"
,   ["8.5"]   = "R2015a"
,   ["8.4"]   = "R2014b"
,   ["8.3"]   = "R2014a"
,   ["8.2"]   = "R2013b"
,   ["8.1"]   = "R2013a"
,   ["8.0"]   = "R2012b"
,   ["7.17"]  = "R2012a"
}
local invmatlabvers = {
    r2022a    = "9.12",
    r2021b    = "9.11",
    r2021a    = "9.10",
    r2020b    = "9.9",
    r2020a    = "9.8",
    r2019b    = "9.7",
    r2019a    = "9.6",
    r2018b    = "9.5",
    r2018a    = "9.4",
    r2017b    = "9.3",
    r2017a    = "9.2",
    r2016b    = "9.1",
    r2016a    = "9.0.1",
    r2015b    = "9.0",
    r2015asp1 = "8.5.1",
    r2015a    = "8.5",
    r2014b    = "8.4",
    r2014a    = "8.3",
    r2013b    = "8.2",
    r2013a    = "8.1",
    r2012b    = "8.0",
    r2012a    = "7.17",
}

-- find matlab runtime sdk
--
-- @return          the matlab runtime sdk. e.g. {sdkdir = ..., includedirs = ..., linkdirs = ..., .. }
--
-- @code
--
-- local sdk = find_matlab_runtime(runtimeversion)
--
-- @endcode
--
function main(runtimeversion)
    runtimeversion = tostring(runtimeversion)
    local result = {sdkdir = "", includedirs = {}, linkdirs = {}, links = {}, bindirs = {}}
    if is_host("windows") then
        local matlabkey = "HKEY_LOCAL_MACHINE\\SOFTWARE\\MathWorks\\MATLAB Runtime"
        local valuekeys = winos.registry_keys(matlabkey)
        if #valuekeys == 0 then
            return nil
        end


        local versionname = nil
        local versionvalue = nil

        local itemkey = nil
        if runtimeversion == nil then
            itemkey = valuekeys[1] .. ";MATLABROOT"
        else
            versionname = matlabvers[runtimeversion]
            if versionname ~= nil then
                versionvalue = invmatlabvers[versionname:lower()]
                itemkey = matlabkey .. "\\" .. runtimeversion .. ";MATLABROOT"
            else
                versionvalue = invmatlabvers[runtimeversion:lower()]
                versionname = matlabvers[versionvalue]
                if versionvalue ~= nil then
                    itemkey = matlabkey .. "\\" .. versionvalue .. ";MATLABROOT"
                else
                    print("allowed values are:")
                    for k,v in pairs(matlabvers) do
                        print("    ", k, v)
                    end
                    raise("MATLAB Runtime version does not exist: " .. runtimeversion)
                end
            end
        end

        local sdkdir = try {function () return winos.registry_query(itemkey) end}
        if not sdkdir then
            return nil
        end

        sdkdir = sdkdir .. "\\v" .. versionvalue:gsub("%.", "")

        result.sdkdir = sdkdir
        result.includedirs = path.join(sdkdir, "extern", "include")
        result.bindirs = {
            path.join(sdkdir, "bin", "win64"),
            path.join(sdkdir, "runtime", "win64"),
        }
        -- find lib dirs
        for _, value in ipairs(os.dirs(path.join(sdkdir, "extern", "lib", "**"))) do
            local dirbasename = path.basename(value)
            if not dirbasename:startswith("win") then
                result.linkdirs[dirbasename] = value
            end
        end
        -- find lib
        for _, value in pairs(result.linkdirs) do
            local dirbasename = path.basename(value)
            result.links[dirbasename] = path.join(value, "*")
        end
    end
    return result
end
