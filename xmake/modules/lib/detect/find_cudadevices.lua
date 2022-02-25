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
-- @author      OpportunityLiu
-- @file        find_cudadevices.lua
--

-- imports
import("core.base.option")
import("core.platform.platform")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_tool")

-- a magic string to filter output
local _PRINT_SUFFIX = "<find_cudadevices>"

-- filter stdout and stderr with _PRINT_SUFFIX
function _get_lines(str)
    local result = {}
    for _, l in ipairs(str:split("\n")) do
        if l:startswith(_PRINT_SUFFIX) then
            table.insert(result, l:sub(#_PRINT_SUFFIX + 1))
        end
    end
    return result
end

-- parse a single value
--
-- format:
-- 1. a number:     `2048`
-- 2. an array:     `(65536, 2048, 2048)`
-- 3. bool value:   `true` or `false`
-- 4. string:       `"string"`
--
function _parse_value(value)
    local num = tonumber(value)
    if num then return num end

    if value:lower() == "true" then return true end
    if value:lower() == "false" then return false end
    if value:startswith('"') and value:endswith('"') then
        return value:sub(2, -2)
    end

    if value:startswith("(") and value:endswith(")") then
        local values = value:sub(2, -2):split(",")
        local result = {}
        for _, v in ipairs(values) do
            table.insert(result, _parse_value(v:trim()))
        end
        return result
    end

    raise("don't know how to parse value: %s", value)
end


-- parse single line
--
-- format:
--     key = value
--
function _parse_line(line, device)
    local key = line:match("%s+(%g+) = .+")
    local value = line:match("%s+%g+ = (.+)")
    if key and value then
        key = key:trim()
        value = value:trim()
        assert(not device[key], "duplicate key: " .. key)
        device[key] = _parse_value(value)
    end
end

-- parse filtered lines
function _parse_result(lines, verbose)

    if #lines == 0 then
        -- not a failure, returns {} rather than nil
        utils.warning("no cuda devices was found")
        return {}
    end

    local devices = {}
    local currentDevice = nil
    for _, l in ipairs(lines) do
        if verbose then
            cprint("${dim}> %s", l)
        end
        local devId = tonumber(l:match("%s*DEVICE #(%d+)"))
        if devId then
            currentDevice = { ["$id"] = devId }
            table.insert(devices, currentDevice)
        elseif currentDevice then
            _parse_line(l, currentDevice)
        end
    end
    return devices
end

-- find devices
function _find_devices(verbose, opt)

    -- find nvcc
    local nvcc = assert(find_tool("nvcc"), "nvcc not found")

    -- trace
    if verbose then
        cprint("${dim}checking for cuda devices")
    end

    -- get cuda devices
    local sourcefile = path.join(os.programdir(), "scripts", "find_cudadevices.cpp")
    local outfile = os.tmpfile({ramdisk = false}) -- no execution permision in docker's /shm
    local compile_errors = nil
    local results, errors = try
    {
        function ()
            local args = { sourcefile, "-run", "-o", outfile , '-DPRINT_SUFFIX="' .. _PRINT_SUFFIX .. '"' }
            if opt.arch == "x86" then
                table.insert(args, "-m32")
            elseif opt.arch == "x64" or opt.arch == "x86_64" then
                table.insert(args, "-m64")
            end
            return os.iorunv(nvcc.program, args, {envs = opt.envs})
        end,
        catch
        {
            function (errs)
                compile_errors = tostring(errs)
            end
        }
    }

    if compile_errors then
        if not option.get("diagnosis") then
            compile_errors = compile_errors:split('\n')[1]
        end
        utils.warning("failed to find cuda devices: " .. compile_errors)
        return nil
    end

    -- clean up
    os.tryrm(outfile)
    os.tryrm(outfile .. ".*")

    -- get results
    local results_lines = _get_lines(results)
    local errors_lines = _get_lines(errors)
    if #errors_lines ~= 0 then
        utils.warning("failed to find cuda devices: " .. table.concat(errors_lines, "\n"))
        return nil
    end

    -- print raw result only with -D flags
    local devices = _parse_result(results_lines, option.get("diagnosis"))
    if verbose then
        for _, v in ipairs(devices) do
            cprint("${dim}> found device #%d: ${green bright}%s${reset dim} with compute ${bright}%d.%d${reset dim} capability", v["$id"], v.name, v.major, v.minor)
        end
    end
    return devices
end

-- get devices array form cache or via _find_devices
function _get_devices(opt)

    -- init cachekey
    local cachekey = "find_cudadevices"
    if opt.cachekey then
        cachekey = cachekey .. "_" .. opt.cachekey
    end

    -- check cache
    local cachedata = detectcache:get(cachekey) or {}
    if cachedata.succeed and not opt.force then
        return cachedata.data
    end

    local verbose = opt.verbose or option.get("verbose") or option.get("diagnosis")
    local devices = _find_devices(verbose, opt)
    if devices then
        cachedata = { succeed = true, data = devices }
    else
        cachedata = { succeed = false }
        devices = {}
    end

    -- fill cache
    detectcache:set(cachekey, cachedata)
    detectcache:save()
    return devices
end

function _skip_compute_mode_prohibited(devices)
    local results = {}
    local cuda_compute_mode_prohibited = 2
    for _, dev in ipairs(devices) do
        if dev.computeMode ~= cuda_compute_mode_prohibited then
            table.insert(results, dev)
        end
    end
    return results
end

function _min_sm_arch(devices, min_sm_arch)
    local results = {}
    for _, dev in ipairs(devices) do
        if dev.major * 10 + dev.minor >= min_sm_arch then
            table.insert(results, dev)
        end
    end
    return results
end

function _order_by_flops(devices)

    local ngpu_arch_cores_per_sm =
    {
        [30] =    192
    ,   [32] =    192
    ,   [35] =    192
    ,   [37] =    192
    ,   [50] =    128
    ,   [52] =    128
    ,   [53] =    128
    ,   [60] =     64
    ,   [61] =    128
    ,   [62] =    128
    ,   [70] =     64
    ,   [72] =     64
    ,   [75] =     64
    ,   [80] =     64
    ,   [86] =    128
    ,   [87] =    128
    }

    for _, dev in ipairs(devices) do
        local sm_per_multiproc = 0
        if dev.major == 9999 and dev.minor == 9999 then
            sm_per_multiproc = 1
        else
            sm_per_multiproc = ngpu_arch_cores_per_sm[dev.major * 10 + dev.minor] or 64;
        end
        dev["$flops"] = dev.multiProcessorCount * sm_per_multiproc * dev.clockRate
    end

    table.sort(devices, function (a,b) return a["$flops"] > b["$flops"] end)
    return devices
end

-- find cuda devices of the host
--
-- @param opt   the options
--              e.g. { verbose = false, force = false, cachekey = "xxxx", min_sm_arch = 35, skip_compute_mode_prohibited = false, order_by_flops = true }
--
-- @return      { { ["$id"] = 0, name = "GeForce GTX 960M", major = 5, minor = 0, ... }, ... }
--              for all keys, see https://docs.nvidia.com/cuda/cuda-runtime-api/structcudaDeviceProp.html#structcudaDeviceProp
--              keys might be differ as your cuda version varies
--
function main(opt)

    -- init options
    opt = opt or {}

    -- get devices
    local devices = _get_devices(opt)

    -- apply filters
    if opt.min_sm_arch then
        devices = _min_sm_arch(devices, opt.min_sm_arch)
    end
    if opt.skip_compute_mode_prohibited then
        devices = _skip_compute_mode_prohibited(devices)
    end
    if opt.order_by_flops then
        devices = _order_by_flops(devices)
    end

    return devices
end
