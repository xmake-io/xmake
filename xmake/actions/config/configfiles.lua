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
-- @file        configfiles.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")

-- get all configuration files
function _get_configfiles()
    local configfiles = {}
    for _, target in pairs(project.targets()) do
        if target:get("enabled") ~= false then

            -- get configuration files for target
            local srcfiles, dstfiles, fileinfos = target:configfiles()
            for idx, srcfile in ipairs(srcfiles) do

                -- get destinate file and file info
                local dstfile  = dstfiles[idx]
                local fileinfo = fileinfos[idx]

                -- get source info
                local srcinfo = configfiles[dstfile]
                if not srcinfo then
                    srcinfo = {}
                    configfiles[dstfile] = srcinfo
                end

                -- save source file
                if srcinfo.srcfile then
                    assert(path.absolute(srcinfo.srcfile) == path.absolute(srcfile), "file(%s) and file(%s) are writing a same file(%s)", srcfile, srcinfo.srcfile, dstfile)
                else
                    srcinfo.srcfile  = srcfile
                    srcinfo.fileinfo = fileinfo
                end

                -- save targets
                srcinfo.targets = srcinfo.targets or {}
                table.insert(srcinfo.targets, target)
            end
        end
    end
    return configfiles
end

-- get the builtin variables
function _get_builtinvars_target(target)

    -- get version variables
    local builtinvars = {}
    local version, version_build = target:version()
    if version then
        builtinvars.VERSION = version
        try {function ()
            local v = semver.new(version)
            if v then
                builtinvars.VERSION_MAJOR = v:major()
                builtinvars.VERSION_MINOR = v:minor()
                builtinvars.VERSION_ALTER = v:patch()
            end
        end}
        if version_build then
            builtinvars.VERSION_BUILD = version_build
        end
    end
    return builtinvars
end

-- get the global builtin variables
function _get_builtinvars_global()
    local builtinvars = _g.builtinvars_global
    if builtinvars == nil then
        builtinvars =
        {
            arch  = config.get("arch") or os.arch()
        ,   plat  = config.get("plat") or os.host()
        ,   host  = os.host()
        ,   mode  = config.get("mode") or "release"
        ,   debug = is_mode("debug") and 1 or 0
        ,   os    = platform.os()
        }
        local builtinvars_upper = {}
        for name, value in pairs(builtinvars) do
            builtinvars_upper[name:upper()] = type(value) == "string" and value:upper() or value
        end
        table.join2(builtinvars, builtinvars_upper)
        _g.builtinvars_global = builtinvars
    end
    return builtinvars
end

-- generate the configuration file
function _generate_configfile(srcfile, dstfile, fileinfo, targets)

    -- trace
    if option.get("verbose") then
        cprint("${dim}generating %s to %s ..", srcfile, dstfile)
    end

    -- only copy it?
    local generated = false
    if fileinfo.onlycopy then
        if os.mtime(srcfile) > os.mtime(dstfile) then
            os.cp(srcfile, dstfile)
            generated = true
        end
    else
        -- generate to the temporary file first
        local dstfile_tmp = path.join(os.tmpdir(), hash.uuid4(srcfile))
        os.tryrm(dstfile_tmp)
        os.cp(srcfile, dstfile_tmp)

        -- get all variables
        local variables = fileinfo.variables or {}
        for _, target in ipairs(targets) do

            -- get variables from the target
            for name, value in pairs(target:get("configvar")) do
                if variables[name] == nil then
                    variables[name] = table.unwrap(value)
                end
            end

            -- get variables from the target.options
            for _, opt in ipairs(target:orderopts()) do
                for name, value in pairs(opt:get("configvar")) do
                    if variables[name] == nil then
                        variables[name] = table.unwrap(value)
                    end
                end
            end

            -- get variables from the target.packages
            for _, pkg in ipairs(target:orderpkgs()) do
                for name, value in pairs(pkg:get("configvar")) do
                    if variables[name] == nil then
                        variables[name] = table.unwrap(value)
                    end
                end
            end

            -- get the builtin variables from the target
            for name, value in pairs(_get_builtinvars_target(target)) do
                if variables[name] == nil then
                    variables[name] = value
                end
            end
        end
        -- get the global builtin variables
        for name, value in pairs(_get_builtinvars_global()) do
            if variables[name] == nil then
                variables[name] = value
            end
        end

        -- replace all variables
        local pattern = fileinfo.pattern or "%${(.-)}"
        io.gsub(dstfile_tmp, "(" .. pattern .. ")", function(_, variable)

            -- get variable name
            variable = variable:trim()

            -- is ${define variable}?
            local isdefine = false
            if variable:startswith("define ") then
                variable = variable:split("%s")[2]
                isdefine = true
            end

            -- is ${default variable xxx}?
            local default = nil
            local isdefault = false
            if variable:startswith("default ") then
                local varinfo = variable:split("%s")
                variable  = varinfo[2]
                default   = varinfo[3]
                isdefault = true
                assert(default ~= nil, "please set default value for variable(%s)", variable)
            end

            -- get variable value
            local value = variables[variable]
            if isdefine then
                if value == nil then
                    value = ("/* #undef %s */"):format(variable)
                elseif type(value) == "boolean" then
                    if value then
                        value = ("#define %s 1"):format(variable)
                    else
                        value = ("/* #define %s 0 */"):format(variable)
                    end
                elseif type(value) == "number" then
                    value = ("#define %s %d"):format(variable, value)
                elseif type(value) == "string" then
                    value = ("#define %s \"%s\""):format(variable, value)
                else
                    raise("unknown variable(%s) type: %s", variable, type(value))
                end
            elseif isdefault then
                if value == nil then
                    value = default
                else
                    value = tostring(value)
                end
            else
                assert(value ~= nil, "cannot get variable(%s) in %s.", variable, srcfile)
            end
            dprint("  > replace %s -> %s", variable, value)
            return value
        end)

        -- update file if the content is changed
        if os.isfile(dstfile_tmp) then
            if os.isfile(dstfile) then
                if io.readfile(dstfile_tmp) ~= io.readfile(dstfile) then
                    os.cp(dstfile_tmp, dstfile)
                    generated = true
                end
            else
                os.cp(dstfile_tmp, dstfile)
                generated = true
            end
        end
    end

    -- trace
    cprint("generating %s ... %s", srcfile, generated and "${color.success}${text.success}" or "${color.success}cache")
end

-- the main entry function
function main()

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- get all configuration files
    local configfiles = _get_configfiles()

    -- generate all configuration files
    for dstfile, srcinfo in pairs(configfiles) do
        _generate_configfile(srcinfo.srcfile, dstfile, srcinfo.fileinfo, srcinfo.targets)
    end

    -- leave project directory
    os.cd(oldir)
end
