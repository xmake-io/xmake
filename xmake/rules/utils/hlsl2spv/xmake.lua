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
-- @file        xmake.lua
--

-- compile glsl shader to spirv file, .spv
--
-- e.g.
-- compile *.hlsl/*.hlsl to *.spv/*.spv files
--   add_rules("utils.hlsl2spv", {outputdir = "build"})
--
-- compile *.vert/*.frag and generate binary c header files
--   add_rules("utils.hlsl2spv", {bin2c = true})
--
-- in c code:
--   static unsigned char g_test_frag_spv_data[] = {
--      #include "test.spv.h"
--   };
--
--
rule("utils.hlsl2spv")
    set_extensions(".hlsl")
    on_load(function (target)
        local is_bin2c = target:extraconf("rules", "utils.hlsl2spv", "bin2c")
        if is_bin2c then
            local headerdir = path.join(target:autogendir(), "rules", "utils", "hlsl2spv")
            if not os.isdir(headerdir) then
                os.mkdir(headerdir)
            end
            target:add("includedirs", headerdir)
        end
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile_hlsl, opt)
        import("lib.detect.find_tool")

        local dxc = assert(find_tool("dxc"), "dxc not found!")

        -- hlsl to spv
        local basename_with_type = path.basename(sourcefile_hlsl)
        local shadertype = path.extension(basename_with_type):sub(2)
        if shadertype == "" then
            -- if not specify shader type, considered it a header, skip
            wprint("hlsl2spv: shader type not specified, skip %s", sourcefile_hlsl)
            return
        end

        local targetenv = target:extraconf("rules", "utils.hlsl2spv", "targetenv") or "vulkan1.0"
        local outputdir = target:extraconf("rules", "utils.hlsl2spv", "outputdir") or path.join(target:autogendir(), "rules", "utils", "hlsl2spv")
        local hlslversion = target:extraconf("rules", "utils.hlsl2spv", "hlslversion") or "2018"
        local spvfilepath = path.join(outputdir, basename_with_type .. ".spv")

        local shadermodel = target:extraconf("rules", "utils.hlsl2spv", "shadermodel") or "6.0"
        local sm = shadermodel:gsub("%.", "_")
        local dxc_profile = shadertype .. "_" .. sm

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.hlsl %s", sourcefile_hlsl)
        batchcmds:mkdir(outputdir)
        batchcmds:vrunv(dxc.program, {path(sourcefile_hlsl), "-spirv", "-HV", hlslversion, "-fspv-target-env=" .. targetenv, "-E", "main", "-T", dxc_profile, "-Fo", path(spvfilepath)})

        -- bin2c
        local outputfile = spvfilepath
        local is_bin2c = target:extraconf("rules", "utils.hlsl2spv", "bin2c")
        if is_bin2c then
            -- get header file
            local headerdir = outputdir
            local headerfile = path.join(headerdir, path.filename(spvfilepath) .. ".h")

            target:add("includedirs", headerdir)
            outputfile = headerfile

            -- add commands
            local argv = {"lua", "private.utils.bin2c", "--nozeroend", "-i", path(spvfilepath), "-o", path(headerfile)}
            batchcmds:vrunv(os.programfile(), argv, {envs = {XMAKE_SKIP_HISTORY = "y"}})
        end

        batchcmds:add_depfiles(sourcefile_hlsl)
        batchcmds:set_depmtime(os.mtime(outputfile))
        batchcmds:set_depcache(target:dependfile(outputfile))
    end)

    after_clean(function (target, batchcmds, sourcefile_hlsl)
        import("private.action.clean.remove_files")

        local outputdir = target:extraconf("rules", "utils.hlsl2spv", "outputdir") or path.join(target:targetdir(), "shader")
        remove_files(path.join(outputdir, "*.spv"))
        remove_files(path.join(outputdir, "*.spv.h"))
    end)
