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

-- @see https://github.com/xmake-io/xmake/issues/3257
rule("iverilog.binary")
    set_extensions(".v", ".sv", ".vhd")
    on_load(function (target)
        target:set("kind", "binary")
        if not target:get("extension") then
            target:set("extension", ".vvp")
        end
    end)

    on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
    end)

    on_linkcmd(function (target, batchcmds, opt)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local iverilog = assert(toolchain:config("iverilog"), "iverilog not found!")

        local targetfile = target:targetfile()
        local targetdir = path.directory(targetfile)
        local argv = {"-o", targetfile}
        local sourcebatch = target:sourcebatches()["iverilog.binary"]
        local sourcefiles = table.wrap(sourcebatch.sourcefiles)
        assert(#sourcefiles > 0, "no source files!")

        -- get languages
        --
        -- Select the Verilog language generation to support in the compiler.
        -- This selects between v1364-1995, v1364-2001, v1364-2005, v1800-2005, v1800-2009, v1800-2012.
        --
        local language_v
        local languages = target:get("languages")
        if languages then
            for _, language in ipairs(languages) do
                if language:startswith("v") then
                    language_v = language
                    break
                end
            end
        end
        if language_v then
            local maps = {
                ["v1364-1995"] = "-g1995",
                ["v1364-2001"] = "-g2001",
                ["v1364-2005"] = "-g2005",
                ["v1800-2005"] = "-g2005-sv",
                ["v1800-2009"] = "-g2009",
                ["v1800-2012"] = "-g2012",
            }
            local flag = maps[language_v]
            if flag then
                table.insert(argv, flag)
            else
                assert("unknown language(%s) for iverilog!", language_v)
            end
        else
            local extension = path.extension(sourcefiles[1])
            if extension == ".vhd" then
                table.insert(argv, "-g2012")
            end
        end

        -- get defines
        for _, define in ipairs((target:get_from("defines", "*"))) do
            table.insert(argv, "-D" .. define)
        end

        -- get includedirs
        local includedirs = target:get("includedirs")
        if includedirs then
            for _, includedir in ipairs(includedirs) do
                table.insert(argv, path(includedir, function (v) return "-I" .. v end))
            end
        end

        -- get flags
        local flags = target:values("iverilog.flags")
        if flags then
            table.join2(argv, flags)
        end

        -- do build
        table.join2(argv, sourcefiles)
        batchcmds:show_progress(opt.progress, "${color.build.target}linking.iverilog %s", path.filename(targetfile))
        batchcmds:mkdir(targetdir)
        batchcmds:vrunv(iverilog, argv)
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(targetfile))
        batchcmds:set_depcache(target:dependfile(targetfile))
    end)

    on_run(function (target)
        local toolchain = assert(target:toolchain("iverilog"), 'we need set_toolchains("iverilog") in target("%s")', target:name())
        local vvp = assert(toolchain:config("vvp"), "vvp not found!")
        os.execv(vvp, {"-n", target:targetfile()})
    end)
