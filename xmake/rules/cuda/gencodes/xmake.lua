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

-- define rule: gencodes
rule("cuda.gencodes")

    -- add cuda `-gencode` flags to target
    --
    -- the gpu arch format syntax
    -- - compute_xx                   --> `-gencode arch=compute_xx,code=compute_xx`
    -- - sm_xx                        --> `-gencode arch=compute_xx,code=sm_xx`
    -- - sm_xx,sm_yy                  --> `-gencode arch=compute_xx,code=[sm_xx,sm_yy]`
    -- - compute_xx,sm_yy             --> `-gencode arch=compute_xx,code=sm_yy`
    -- - compute_xx,sm_yy,sm_zz       --> `-gencode arch=compute_xx,code=[sm_yy,sm_zz]`
    -- - native                       --> match the fastest cuda device on current host,
    --                                    eg. for a Tesla P100, `-gencode arch=compute_60,code=sm_60` will be added,
    --                                    if no available device is found, no `-gencode` flags will be added
    --                                    @seealso xmake/modules/lib/detect/find_cudadevices
    --
    before_load(function (target)

        local function set (list)
            local result = {}
            for _, l in ipairs(list) do result[l] = true end
            return result
        end

        -- sm_20 and compute_20 is supported until CUDA 8
        local knownVArchs = set { 20, 30, 32, 35, 37, 50, 52, 53, 60, 61, 62, 70, 72, 75, }
        local knownRArchs = set { 20, 30, 32, 35, 37, 50, 52, 53, 60, 61, 62, 70, 72, 75, }

        local function nf_cugencode(archs)

            if type(archs) ~= 'string' then
                return nil
            end
            archs = archs:trim():lower()
            if archs == 'native' then
                import("lib.detect.find_cudadevices")
                local device = find_cudadevices({ skip_compute_mode_prohibited = true, order_by_flops = true })[1]
                if device then
                    return nf_cugencode('sm_' .. device.major .. device.minor)
                end
                return nil
            end

            local vArch = nil
            local rArchs = {}

            local function parse_arch(value, prefix, knowList)
                if not value:startswith(prefix) then
                    return nil
                end
                local arch = tonumber(value:sub(#prefix + 1)) or tonumber(value:sub(#prefix + 2))
                if arch == nil then
                    raise("Unknown architecture: " .. value)
                end
                if not knowList[arch] then
                    if arch <= table.maxn(knowList) then
                        raise("Unknown architecture: " .. prefix .. "_" .. arch)
                    else
                        utils.warning("Unknown architecture: " .. prefix .. "_" .. arch)
                    end
                end
                return arch
            end

            for _, v in ipairs(archs:split(',')) do
                local arch = v:trim()
                local tempRArch = parse_arch(arch, 'sm', knownRArchs)
                if tempRArch then
                    table.insert(rArchs, tempRArch)
                end

                local tempVArch = parse_arch(arch, 'compute', knownVArchs)
                if tempVArch then
                    if vArch ~= nil then
                        raise("More than one virtual architecture is defined in one gpu gencode option: compute_" .. vArch .. " and compute_" .. tempVArch)
                    end
                    vArch = tempVArch
                end
                if not (tempRArch or tempVArch) then
                    raise("Unknown architecture: " .. arch)
                end
            end

            if vArch == nil and #rArchs == 0 then
                return nil
            end
            if #rArchs == 0 then
                return '-gencode arch=compute_' .. vArch .. ',code=compute_' .. vArch
            end

            rArchs = table.unique(rArchs)
            vArch = vArch or math.min(unpack(rArchs))
            if #rArchs == 1 then
                return '-gencode arch=compute_' .. vArch .. ',code=sm_' .. rArchs[1]
            else
                return '-gencode arch=compute_' .. vArch .. ',code=[sm_' .. table.concat(rArchs, ',sm_') .. ']'
            end
        end

        local cugencodes = table.wrap(target:get("cugencodes"))
        for _, opt in ipairs(target:orderopts()) do
            table.join2(gencodes, opt:get("cugencodes"))
        end
        for _, v in ipairs(cugencodes) do
            local flag = nf_cugencode(v)
            if flag then
                target:add('cuflags', flag)
                target:add('culdflags', flag)
            end
        end
    end)
rule_end()
