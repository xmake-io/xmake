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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        configfiles.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

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
        local dstfile_tmp = path.join(os.tmpdir(), hash.uuid(srcfile))
        os.tryrm(dstfile_tmp)
        os.cp(srcfile, dstfile_tmp)

        -- get all variables
        local variables = fileinfo.variables or {}
        for _, target in ipairs(targets) do
            for name, value in pairs(target:get("configvar")) do
                if variables[name] == nil then
                    variables[name] = table.unwrap(value)
                end
            end
        end

        -- replace all variables
        local pattern = fileinfo.pattern or "%${(.-)}"
        io.gsub(dstfile_tmp, "(" .. pattern .. ")", function(_, variable) 
            local value = variables[variable:trim()] 
            assert(value ~= nil, "cannot get variable(%s) in %s.", variable, srcfile)
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
