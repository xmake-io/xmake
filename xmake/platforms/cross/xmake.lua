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
-- @file        xmake.lua
--

-- define platform
platform("cross")

    -- set hosts
    set_hosts("macosx", "linux", "windows", "bsd")

    -- set archs
    set_archs("i386", "x86_64", "arm", "arm64", "mips", "mips64", "riscv", "riscv64", "s390x", "ppc", "ppc64", "sh4")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).so")
    set_formats("symbol", "$(name).sym")

    -- on check
    on_check(function (platform)
        import("core.project.config")
        import("detect.sdks.find_cross_toolchain")

        -- detect arch
        local arch = config.get("arch")
        if not arch then
            local cross  = config.get("cross")
            if not cross then
                local cross_toolchain = find_cross_toolchain(config.get("sdk"), {bindir = config.get("bin")})
                if cross_toolchain then
                    cross = cross_toolchain.cross
                end
            end
            arch = "none"
            if cross then
                if cross:find("aarch64", 1, true) then
                    arch = "arm64"
                elseif cross:find("arm", 1, true) then
                    arch = "arm"
                elseif cross:find("mips64", 1, true) then
                    arch = "mips64"
                elseif cross:find("mips", 1, true) then
                    arch = "mips"
                elseif cross:find("riscv64", 1, true) then
                    arch = "riscv64"
                elseif cross:find("riscv", 1, true) then
                    arch = "riscv"
                elseif cross:find("s390x", 1, true) then
                    arch = "s390x"
                elseif cross:find("powerpc64", 1, true) then
                    arch = "ppc64"
                elseif cross:find("powerpc", 1, true) then
                    arch = "ppc"
                elseif cross:find("sh4", 1, true) then
                    arch = "sh4"
                elseif cross:find("x86_64", 1, true) then
                    arch = "x86_64"
                elseif cross:find("i386", 1, true) or cross:find("i686", 1, true) then
                    arch = "i386"
                end
            end
            config.set("arch", arch)
            cprint("checking for architecture ... ${color.success}%s", arch)
        end
    end)

    -- set toolchains
    set_toolchains("envs", "cross")


