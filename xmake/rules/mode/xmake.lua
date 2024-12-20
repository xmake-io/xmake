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

-- define rule: debug mode
rule("mode.debug")
    on_config(function (target)

        -- is debug mode now? xmake f -m debug
        if is_mode("debug") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end

            -- #5777: '--device-debug (-G)' overrides '--generate-line-info (-lineinfo)' in nvcc
            target:add("cuflags", "-G")
        end
    end)

-- define rule: release mode
rule("mode.release")
    on_config(function (target)

        -- is release mode now? xmake f -m release
        if is_mode("release") then

            -- set the symbols visibility: hidden
            if not target:get("symbols") and target:kind() ~= "shared" then
                target:set("symbols", "hidden")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- strip all symbols
            if not target:get("strip") then
                target:set("strip", "all")
            end

            -- enable NDEBUG macros to disables standard-C assertions
            target:add("cxflags", "-DNDEBUG")
            target:add("cuflags", "-DNDEBUG")
        end
    end)

-- define rule: release with debug symbols mode
rule("mode.releasedbg")
    on_config(function (target)

        -- is releasedbg mode now? xmake f -m releasedbg
        if is_mode("releasedbg") then

            -- set the symbols visibility: debug
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- strip all symbols, but it will generate debug symbol file because debug/symbols is setted
            if not target:get("strip") then
                target:set("strip", "all")
            end

            -- enable NDEBUG macros to disables standard-C assertions
            target:add("cxflags", "-DNDEBUG")
            target:add("cuflags", "-DNDEBUG")

            -- #5777: '--device-debug (-G)' overrides '--generate-line-info (-lineinfo)' in nvcc
            target:add("cuflags", "-lineinfo")
        end
    end)

-- define rule: release with minsize mode
rule("mode.minsizerel")
    on_config(function (target)

        -- is minsizerel mode now? xmake f -m minsizerel
        if is_mode("minsizerel") then

            -- set the symbols visibility: hidden
            if not target:get("symbols") then
                target:set("symbols", "hidden")
            end

            -- enable optimization
            if not target:get("optimize") then
                target:set("optimize", "smallest")
            end

            -- strip all symbols
            if not target:get("strip") then
                target:set("strip", "all")
            end

            -- enable NDEBUG macros to disables standard-C assertions
            target:add("cxflags", "-DNDEBUG")
            target:add("cuflags", "-DNDEBUG")
        end
    end)

-- define rule: profile mode
rule("mode.profile")
    on_config(function (target)

        -- is profile mode now? xmake f -m profile
        if is_mode("profile") then

            -- set the symbols visibility: debug
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            if target:is_plat("windows") then
                -- enable vs profile
                target:add("ldflags", "/profile")
            else
                -- enable gprof
                target:add("cxflags", "-pg")
                target:add("mxflags", "-pg")
                target:add("ldflags", "-pg")
            end

            -- enable NDEBUG macros to disables standard-C assertions
            target:add("cxflags", "-DNDEBUG")
            target:add("cuflags", "-DNDEBUG")

            -- #5777: '--device-debug (-G)' overrides '--generate-line-info (-lineinfo)' in nvcc
            target:add("cuflags", "-lineinfo")
        end
    end)

-- define rule: coverage mode
rule("mode.coverage")
    on_config(function (target)

        -- is coverage mode now? xmake f -m coverage
        if is_mode("coverage") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end

            -- enable coverage
            target:add("cxflags", "--coverage")
            target:add("mxflags", "--coverage")
            target:add("ldflags", "--coverage")
            target:add("shflags", "--coverage")
        end
    end)

-- define rule: asan mode
rule("mode.asan")

    -- we use after_load because c++.build.sanitizer rule/on_config need it
    after_load(function (target)

        -- is asan mode now? xmake f -m asan
        if is_mode("asan") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- enable asan checker
            target:set("policy", "build.sanitizer.address", true)

            -- we should use "build.sanitizer.address" instead of it.
            wprint("deprecated: please use set_policy(\"build.sanitizer.address\", true) instead of \"mode.asan\".")
        end
    end)

-- define rule: tsan mode
rule("mode.tsan")
    after_load(function (target)

        -- is tsan mode now? xmake f -m tsan
        if is_mode("tsan") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- enable tsan checker
            target:set("policy", "build.sanitizer.thread", true)

            -- we should use "build.sanitizer.thread" instead of it.
            wprint("deprecated: please use set_policy(\"build.sanitizer.thread\", true) instead of \"mode.tsan\".")
        end
    end)

-- define rule: msan mode
rule("mode.msan")
    after_load(function (target)

        -- is msan mode now? xmake f -m msan
        if is_mode("msan") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- enable msan checker
            target:set("policy", "build.sanitizer.memory", true)

            -- we should use "build.sanitizer.memory" instead of it.
            wprint("deprecated: please use set_policy(\"build.sanitizer.memory\", true) instead of \"mode.msan\".")
        end
    end)

-- define rule: lsan mode
rule("mode.lsan")
    after_load(function (target)

        -- is lsan mode now? xmake f -m lsan
        if is_mode("lsan") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- enable lsan checker
            target:set("policy", "build.sanitizer.leak", true)

            -- we should use "build.sanitizer.leak" instead of it.
            wprint("deprecated: please use set_policy(\"build.sanitizer.leak\", true) instead of \"mode.lsan\".")
        end
    end)

-- define rule: ubsan mode
rule("mode.ubsan")
    after_load(function (target)

        -- is ubsan mode now? xmake f -m ubsan
        if is_mode("ubsan") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end

            -- enable ubsan checker
            target:set("policy", "build.sanitizer.undefined", true)

            -- we should use "build.sanitizer.undefined" instead of it.
            wprint("deprecated: please use set_policy(\"build.sanitizer.undefined\", true) instead of \"mode.ubsan\".")
        end
    end)

-- define rule: valgrind mode
rule("mode.valgrind")
    on_config(function (target)

        -- is valgrind mode now? xmake f -m valgrind
        if is_mode("valgrind") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable optimization
            if not target:get("optimize") then
                if target:is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end
        end
    end)

-- define rule: check mode (deprecated)
rule("mode.check")
    on_config(function (target)

        -- is check mode now? xmake f -m check
        if is_mode("check") then

            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end

            -- attempt to enable some checkers for pc
            if is_mode("check") and is_arch("i386", "x86_64") then
                target:add("cxflags", "-fsanitize=address", "-ftrapv")
                target:add("mxflags", "-fsanitize=address", "-ftrapv")
                target:add("ldflags", "-fsanitize=address")
                target:add("shflags", "-fsanitize=address")
            end
        end
    end)
