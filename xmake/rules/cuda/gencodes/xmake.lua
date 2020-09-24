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

        -- imports
        import("core.platform.platform")
        import("lib.detect.find_cudadevices")
        import("core.base.hashset")

        -- sm_20 and compute_20 is supported until CUDA 8
        -- sm_30 and compute_30 is supported until CUDA 10
        local known_v_archs = hashset.of(20, 30, 32, 35, 37, 50, 52, 53, 60, 61, 62, 70, 72, 75, 80)
        local known_r_archs = hashset.of(20, 30, 32, 35, 37, 50, 52, 53, 60, 61, 62, 70, 72, 75, 80)

        local function nf_cugencode(archs)
            if type(archs) ~= 'string' then
                return nil
            end
            archs = archs:trim():lower()
            if archs == 'native' then
                local device = find_cudadevices({ skip_compute_mode_prohibited = true, order_by_flops = true })[1]
                if device then
                    return nf_cugencode('sm_' .. device.major .. device.minor)
                end
                return nil
            end

            local v_arch = nil
            local r_archs = {}

            local function parse_arch(value, prefix, know_list)
                if not value:startswith(prefix) then
                    return nil
                end
                local arch = tonumber(value:sub(#prefix + 1)) or tonumber(value:sub(#prefix + 2))
                if arch == nil then
                    raise("Unknown architecture: " .. value)
                end
                if not know_list:has(arch) then
                    if arch <= table.maxn(know_list:data()) then
                        raise("Unknown architecture: " .. prefix .. "_" .. arch)
                    else
                        utils.warning("Unknown architecture: " .. prefix .. "_" .. arch)
                    end
                end
                return arch
            end

            for _, v in ipairs(archs:split(',')) do
                local arch = v:trim()
                local temp_r_arch = parse_arch(arch, 'sm', known_r_archs)
                if temp_r_arch then
                    table.insert(r_archs, temp_r_arch)
                end

                local temp_v_arch = parse_arch(arch, 'compute', known_v_archs)
                if temp_v_arch then
                    if v_arch ~= nil then
                        raise("More than one virtual architecture is defined in one gpu gencode option: compute_" .. v_arch .. " and compute_" .. temp_v_arch)
                    end
                    v_arch = temp_v_arch
                end
                if not (temp_r_arch or temp_v_arch) then
                    raise("Unknown architecture: " .. arch)
                end
            end

            if v_arch == nil and #r_archs == 0 then
                return nil
            end

            if #r_archs == 0 then
                return {
                    clang = '--cuda-gpu-arch=sm_' .. v_arch
                ,   nvcc = '-gencode arch=compute_' .. v_arch .. ',code=compute_' .. v_arch }
            end

            if v_arch then
                table.insert(r_archs, v_arch)
            else
                v_arch = math.min(unpack(r_archs))
            end
            r_archs = table.unique(r_archs)

            local clang_flags = {}
            for _, r_arch in ipairs(r_archs) do
                table.insert(clang_flags, '--cuda-gpu-arch=sm_' .. r_arch)
            end

            local nvcc_flags = nil
            if #r_archs == 1 then
                nvcc_flags = '-gencode arch=compute_' .. v_arch .. ',code=sm_' .. r_archs[1]
            else
                nvcc_flags = '-gencode arch=compute_' .. v_arch .. ',code=[sm_' .. table.concat(r_archs, ',sm_') .. ']'
            end

            return { clang = clang_flags, nvcc = nvcc_flags }
        end

        local cugencodes = table.wrap(target:get("cugencodes"))
        for _, opt in ipairs(target:orderopts()) do
            table.join2(cugencodes, opt:get("cugencodes"))
        end
        for _, v in ipairs(cugencodes) do
            local flag = nf_cugencode(v)
            if flag then
                local tool, toolname = platform.tool("cu")
                if (toolname or path.basename(tool)) == "nvcc" then
                    target:add('cuflags', flag.nvcc)
                else
                    target:add('cuflags', flag.clang)
                end
                target:add('culdflags', flag.nvcc)
            end
        end
    end)
rule_end()
