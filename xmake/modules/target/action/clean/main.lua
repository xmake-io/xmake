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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("private.action.clean.remove_files")
import("private.cache.build_cache")

-- the builtin clean main entry
function main(target)

    -- is phony?
    if target:is_phony() then
        return
    end

    -- remove the target file
    local targetfile = target:targetfile()
    remove_files(targetfile)

    -- remove import library of the target file
    -- @see https://github.com/xmake-io/xmake/issues/3052
    if target:is_plat("windows") and target:is_shared() then
        local expfile = path.join(path.directory(targetfile), path.basename(targetfile) .. ".exp")
        local libfile = path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib")
        if os.isfile(expfile) then
            remove_files(libfile)
            remove_files(expfile)
        end
    end

    -- remove the symbol file
    remove_files(target:symbolfile())

    -- remove the c/c++ precompiled header file
    remove_files(target:pcoutputfile("c"))
    remove_files(target:pcoutputfile("cxx"))

    -- TODO remove the header files (deprecated)
    local _, dstheaders = target:headers()
    remove_files(dstheaders)

    -- remove the clean files
    remove_files(target:get("cleanfiles"))

    -- remove all?
    if option.get("all") then

        -- TODO remove the config.h file (deprecated)
        remove_files(target:configheader())

        -- remove all dependent files for each platform
        remove_files(target:dependir({root = true}))

        -- remove all object files for each platform
        remove_files(target:objectdir({root = true}))

        -- remove all autogen files for each platform
        remove_files(target:autogendir({root = true}))

        -- clean build cache
        build_cache.clean()
    else

        -- remove dependent files for the current platform
        remove_files(target:dependir())

        -- remove object files for the current platform
        remove_files(target:objectdir())

        -- remove autogen files for the current platform
        remove_files(target:autogendir())
    end
end

