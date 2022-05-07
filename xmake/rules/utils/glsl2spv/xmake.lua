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
-- compile *.vert/*.frag to *.vert.spv/*.frag.spv files
--   add_rules("utils.glsl2spv", {outputdir = "build"})
--
-- compile *.vert/*.frag and generate binary c header files
--   add_rules("utils.glsl2spv", {bin2c = true})
--
-- in c code:
--   static unsigned char g_test_frag_spv_data[] = {
--      #include "test.frag.spv.h"
--   };
--
--
rule("utils.glsl2spv")
    set_extensions(".vert", ".tesc", ".tese", ".geom", ".comp", ".frag", ".comp", ".mesh", ".task", ".rgen", ".rint", ".rahit", ".rchit", ".rmiss", ".rcall", ".glsl")
    on_load(function (target)
        local is_bin2c = target:extraconf("rules", "utils.glsl2spv", "bin2c")
        if is_bin2c then
            local headerdir = path.join(target:autogendir(), "rules", "utils", "glsl2spv")
            if not os.isdir(headerdir) then
                os.mkdir(headerdir)
            end
            target:add("includedirs", headerdir)
        end
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_glsl, opt)
        import("lib.detect.find_tool")

        -- get glslangValidator
        local glslc
        local glslangValidator = find_tool("glslangValidator")
        if not glslangValidator then
            glslc = find_tool("glslc")
        end
        assert(glslangValidator or glslc, "glslangValidator or glslc not found!")

        -- glsl to spv
        local targetenv = target:extraconf("rules", "utils.glsl2spv", "targetenv") or "vulkan1.0"
        local outputdir = target:extraconf("rules", "utils.glsl2spv", "outputdir") or path.join(target:autogendir(), "rules", "utils", "glsl2spv")
        local spvfilepath = path.join(outputdir, path.filename(sourcefile_glsl) .. ".spv")
        batchcmds:show_progress(opt.progress, "${color.build.object}generating.glsl2spv %s", sourcefile_glsl)
        batchcmds:mkdir(outputdir)
        if glslangValidator then
            batchcmds:vrunv(glslangValidator.program, {"--target-env", targetenv, "-o", path(spvfilepath), path(sourcefile_glsl)})
        else
            batchcmds:vrunv(glslc.program, {"--target-env", targetenv, "-o", path(spvfilepath), path(sourcefile_glsl)})
        end

        -- do bin2c
        local outputfile = spvfilepath
        local is_bin2c = target:extraconf("rules", "utils.glsl2spv", "bin2c")
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

        -- add deps
        batchcmds:add_depfiles(sourcefile_glsl)
        batchcmds:set_depmtime(os.mtime(outputfile))
        batchcmds:set_depcache(target:dependfile(outputfile))
    end)

