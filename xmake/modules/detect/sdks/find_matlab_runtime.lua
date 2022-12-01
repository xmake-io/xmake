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

-- imports
import("detect.sdks.matlab")

-- find matlab runtime sdk
--
-- @return          the matlab runtime sdk. e.g. {sdkdir = ..., includedirs = ..., linkdirs = ..., .. }
--
-- @code
--
-- local sdk = find_matlab_runtime(opt)
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    local version = opt.require_version and tostring(opt.require_version) or nil
    local result = {sdkdir = "", includedirs = {}, linkdirs = {}, links = {}, bindirs = {}}
    if is_host("windows") then
        local matlabkey = "HKEY_LOCAL_MACHINE\\SOFTWARE\\MathWorks\\MATLAB Runtime"
        local valuekeys = winos.registry_keys(matlabkey)
        if #valuekeys == 0 then
            return
        end

        local itemkey
        local versionname
        local versionvalue
        if version == nil then
            local splitvaluekeys = valuekeys[1]:split("\\")
            versionvalue = splitvaluekeys[#splitvaluekeys]
            versionname = matlab.versions()[versionvalue]
            itemkey = valuekeys[1] .. ";MATLABROOT"
        else
            versionname = matlab.versions()[version]
            if versionname ~= nil then
                versionvalue = matlab.versions_names()[versionname:lower()]
                itemkey = matlabkey .. "\\" .. version .. ";MATLABROOT"
            else
                versionvalue = matlab.versions_names()[version:lower()]
                versionname = matlab.versions()[versionvalue]
                if versionvalue ~= nil then
                    itemkey = matlabkey .. "\\" .. versionvalue .. ";MATLABROOT"
                else
                    print("allowed values are:")
                    for k, v in pairs(matlab.versions()) do
                        print("    ", k, v)
                    end
                    raise("MATLAB Runtime version does not exist: " .. version)
                end
            end
        end

        local sdkdir = try {function () return winos.registry_query(itemkey) end}
        if not sdkdir then
            return
        end
        sdkdir = sdkdir .. "\\v" .. versionvalue:gsub("%.", "")
        result.sdkdir = sdkdir
        result.includedirs = path.join(sdkdir, "extern", "include")
        result.bindirs = {
            path.join(sdkdir, "bin", "win64"),
            path.join(sdkdir, "runtime", "win64"),
        }
        for _, value in ipairs(os.dirs(path.join(sdkdir, "extern", "lib", "**"))) do
            local dirbasename = path.basename(value)
            if not dirbasename:startswith("win") then
                result.linkdirs[dirbasename] = value
            end
        end
        for _, value in pairs(result.linkdirs) do
            local dirbasename = path.basename(value)
            result.links[dirbasename] = {}
            for _, filepath in ipairs(os.files(value.."/*.lib")) do
                table.insert(result.links[dirbasename], path.basename(filepath))
            end
            result.links[dirbasename] = table.unique(result.links[dirbasename])
        end
    end
    return result
end

