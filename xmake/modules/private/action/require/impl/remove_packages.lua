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
-- @file        remove_packages.lua
--

-- imports
import("core.base.option")
import("core.package.package")
import("core.cache.localcache")

-- get package configs string
function _get_package_configs_str(manifest_file)
    local manifest = os.isfile(manifest_file) and io.load(manifest_file)
    if manifest then
        local configs = {}
        for k, v in pairs(manifest.configs) do
            if type(v) == "boolean" then
                table.insert(configs, k .. ":" .. (v and "y" or "n"))
            else
                table.insert(configs, k .. ":" .. v)
            end
        end
        local configs_str = #configs > 0 and "[" .. table.concat(configs, ", ") .. "]" or ""
        local limitwidth = math.floor(os.getwinsize().width * 2 / 3)
        if #configs_str > limitwidth then
            configs_str = configs_str:sub(1, limitwidth) .. " ..)"
        end
        return configs_str
    end
end

-- remove package directories
function _remove_packagedirs(packagedir, opt)

    -- clear them
    local package_name = path.filename(packagedir)
    for _, versiondir in ipairs(os.dirs(path.join(packagedir, "*"))) do
        local version = path.filename(versiondir)
        for _, hashdir in ipairs(os.dirs(path.join(versiondir, "*"))) do
            local hash = path.filename(hashdir)
            local references_file = path.join(hashdir, "references.txt")
            local referenced = false
            local references = os.isfile(references_file) and io.load(references_file) or nil
            if references then
                for projectdir, refdate in pairs(references) do
                    if os.isdir(projectdir) then
                        referenced = true
                        break
                    end
                end
            end
            local manifest_file = path.join(hashdir, "manifest.txt")
            local status = nil
            if os.emptydir(hashdir) then
                status = "empty"
            elseif not referenced then
                status = "unused"
            elseif not os.isfile(manifest_file) then
                status = "invalid"
            end
            if not opt.clean or status then
                local configs_str = _get_package_configs_str(manifest_file) or "[]"
                local description = string.format("remove ${color.dump.string}%s-%s${clear}/${yellow}%s${clear}\n  -> ${dim}%s${clear} (${red}%s${clear})", package_name, version, hash, configs_str, status and status or "used")
                local confirm = utils.confirm({default = true, description = description})
                if confirm then
                    os.rm(hashdir)
                end
            end
        end
        if os.emptydir(versiondir) then
            os.rm(versiondir)
        end
    end
    if os.emptydir(packagedir) then
        os.rm(packagedir)
    end
end

-- remove the given or all packages
--
-- @param package_names     the package names list, support lua pattern
-- @param opt               the options, only clean unused packages if pass `{clean = true}`
--
function main(package_names, opt)
    opt = opt or {}
    local installdir = package.installdir()
    if package_names then
        for _, package_name in ipairs(package_names) do
            for _, packagedir in ipairs(os.dirs(path.join(installdir, package_name:sub(1, 1), package_name))) do
                _remove_packagedirs(packagedir, opt)
            end
        end
    else
        for _, packagedir in ipairs(os.dirs(path.join(installdir, "*", "*"))) do
            _remove_packagedirs(packagedir, opt)
        end
    end
end


