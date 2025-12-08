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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

-- compile hlsl shader to spirv file, .spv
--
-- e.g.
-- compile *.hlsl to *.spv files
--   add_rules("utils.hlsl2spv", {outputdir = "build"})
--
-- compile *.hlsl and generate binary c header files
--   add_rules("utils.hlsl2spv", {bin2c = true})
--
-- compile *.hlsl and generate object files for direct linking
--   add_rules("utils.hlsl2spv", {bin2obj = true})
--
-- in c code (bin2c):
--   static unsigned char g_test_ps_spv_data[] = {
--      #include "test.ps.spv.h"
--   };
--
-- in c code (bin2obj):
--   extern const uint8_t _binary_test_ps_spv_start[];
--   extern const uint8_t _binary_test_ps_spv_end[];
--   const uint32_t size = (uint32_t)(_binary_test_ps_spv_end - _binary_test_ps_spv_start);
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
        import("rules.utils.bin2obj.utils", {alias = "bin2obj_utils", rootdir = os.programdir()})
        import("rules.utils.bin2c.utils", {alias = "bin2c_utils", rootdir = os.programdir()})

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

        -- bin2c or bin2obj
        local outputfile = spvfilepath
        local is_bin2c = target:extraconf("rules", "utils.hlsl2spv", "bin2c")
        local is_bin2obj = target:extraconf("rules", "utils.hlsl2spv", "bin2obj")
        if is_bin2c then
            -- generate header file
            -- note: explicitly disable zeroend (SPIR-V is binary format, not null-terminated string)
            local headerfile = bin2c_utils.generate_headerfile(target, batchcmds, spvfilepath, {
                progress = opt.progress,
                headerdir = outputdir,
                zeroend = false  -- SPIR-V is binary format, not null-terminated string
            })
            outputfile = headerfile
        elseif is_bin2obj then
            -- convert to object file using bin2obj
            -- note: zeroend is false by default (SPIR-V is binary format, not null-terminated string)
            local objectfile = bin2obj_utils.generate_objectfile(target, batchcmds, spvfilepath, {
                progress = opt.progress,
                rulename = "utils.hlsl2spv"  -- pass current rule name for config lookup
            })
            outputfile = objectfile
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
        -- object files are cleaned automatically by xmake
    end)
