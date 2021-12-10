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
-- @file        driver_modules.lua
--

-- get linux-headers sdk
function _get_linux_headers_sdk(target)
    local linux_headers = assert(target:pkg("linux-headers"), "please add `add_requires(\"linux-headers\", {configs = {driver_modules = true}})` and `add_packages(\"linux-headers\")` to the given target!")
    local includedirs = linux_headers:get("includedirs") or linux_headers:get("sysincludedirs")
    local version = linux_headers:version()
    local includedir
    local linux_headersdir
    for _, dir in ipairs(includedirs) do
        if dir:find("linux-headers", 1, true) then
            includedir = dir
            linux_headersdir = path.directory(dir)
            break
        end
    end
    assert(linux_headersdir, "linux-headers not found!")
    if not os.isfile(path.join(includedir, "generated/autoconf.h")) and
        not os.isfile(path.join(includedir, "config/auto.conf")) then
        raise("kernel configuration is invalid. include/generated/autoconf.h or include/config/auto.conf are missing.")
    end
    return {version = version, sdkdir = linux_headersdir, includedir = includedir}
end

function load(target)
    -- we need only need binary kind, because we will rewrite on_link
    target:set("kind", "binary")

    -- get and save linux-headers sdk
    local linux_headers = _get_linux_headers_sdk(target)
    target:data_set("linux.driver.linux_headers", linux_headers)

    -- check compiler, we must use gcc
    assert(target:has_tool("cc", "gcc"), "we must use gcc compiler!")

    -- add includedirs
    local sdkdir = linux_headers.sdkdir
    local includedir = linux_headers.includedir
    local archsubdir
    if target:is_arch("x86_64", "i386") then
        archsubdir = path.join(sdkdir, "arch", "x86")
    end
    assert(archsubdir, "unknown arch(%s) for linux driver modules!", target:arch())
    target:add("sysincludedirs", "/usr/lib/gcc/x86_64-linux-gnu/10/include")
    target:add("includedirs", includedir)
    target:add("includedirs", path.join(includedir, "uapi"))
    target:add("includedirs", path.join(includedir, "generated", "uapi"))
    target:add("includedirs", path.join(archsubdir, "include"))
    target:add("includedirs", path.join(archsubdir, "include", "generated"))
    target:add("includedirs", path.join(archsubdir, "include", "uapi"))
    target:add("includedirs", path.join(archsubdir, "include", "generated", "uapi"))
    target:add("cflags", "-include " .. path.join(includedir, "linux", "kconfig.h"))
    target:add("cflags", "-include " .. path.join(includedir, "linux", "compiler_types.h"))

    -- add compilation flags
    target:set("policy", "check.auto_ignore_flags", false)
    target:add("defines", "__KERNEL__", "MODULE", "CC_USING_FENTRY")
    target:add("defines", "KBUILD_BASENAME=\"" .. target:name() .. "\"", "KBUILD_MODNAME=\"" .. target:name() .. "\"")
    if target:is_arch("x86_64", "i386") then
        target:add("defines", "CONFIG_X86_X32_ABI")
    end
    target:set("optimize", "faster") -- we need use -O2 for gcc
    target:set("languages", "gnu89")
    target:add("cflags", "-nostdinc")
    target:add("cflags", "-mno-sse", "-mno-mmx", "-mno-sse2", "-mno-3dnow", "-mno-avx", "-mno-80387", "-mno-fp-ret-in-387")
    target:add("cflags", "-mpreferred-stack-boundary=3", "-mskip-rax-setup", "-mtune=generic", "-mno-red-zone", "-mcmodel=kernel")
    target:add("cflags", "-mindirect-branch=thunk-extern", "-mindirect-branch-register", "-mrecord-mcount", "-mfentry")
    target:add("cflags", "-fmacro-prefix-map=./=", " -fno-strict-aliasing", "-fno-common", "-fshort-wchar", "-fno-PIE")
    target:add("cflags", "-fcf-protection=none", "-falign-jumps=1", "-falign-loops=1", "-fno-asynchronous-unwind-tables")
    target:add("cflags", "-fno-jump-tables", "-fno-delete-null-pointer-checks", "-fno-allow-store-data-races")
    target:add("cflags", "-fno-reorder-blocks", "-fno-ipa-cp-clone", "-fno-partial-inlining", "-fstack-protector-strong")
    target:add("cflags", "-fno-inline-functions-called-once", "-falign-functions=32")
    target:add("cflags", "-fno-strict-overflow", "-fno-stack-check", "-fconserve-stack")
    target:add("cflags", "-fsanitize=kernel-address", "-fasan-shadow-offset=0xdffffc0000000000", "-fsanitize-coverage=trace-pc", "-fsanitize-coverage=trace-cmp")
    target:add("cflags", "--param asan-globals=1", "--param asan-instrumentation-with-call-threshold=0", "--param asan-stack=1", "--param asan-instrument-allocas=1")
end

function link(target, opt)
end
