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

-- imports
import("core.base.option")
import("core.project.depend")
import("core.cache.memcache")
import("lib.detect.find_tool")
import("utils.progress")
import("private.tools.ccache")

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

-- get c system search include directory of gcc
--
-- e.g. gcc -E -Wp,-v -xc /dev/null
--
-- ignoring nonexistent directory "/usr/local/include/x86_64-linux-gnu"
-- ignoring nonexistent directory "/usr/lib/gcc/x86_64-linux-gnu/10/include-fixed"
-- ignoring nonexistent directory "/usr/lib/gcc/x86_64-linux-gnu/10/../../../../x86_64-linux-gnu/include"
-- #include "..." search starts here:
-- #include <...> search starts here:
-- /usr/lib/gcc/x86_64-linux-gnu/10/include        <-- we need get it
-- /usr/local/include
-- /usr/include/x86_64-linux-gnu
-- /usr/include
-- End of search list.
function _get_gcc_includedir(target)
    local key = "gcc.includedir." .. target:plat() .. target:arch()
    local includedir = memcache.get("linux.driver", key)
    if includedir == nil then
        local gcc, toolname = target:tool("cc")
        assert(toolname, "gcc")

        local _, result = try {function () return os.iorunv(gcc, {"-E", "-Wp,-v", "-xc", os.nuldev()}) end}
        if result then
            for _, line in ipairs(result:split("\n", {plain = true})) do
                line = line:trim()
                if os.isdir(line) then
                    includedir = line
                    break
                elseif line:startswith("End") then
                    break
                end
            end
        end
        memcache.set("linux.driver", key, includedir or false)
    end
    return includedir or nil
end

-- get cflags from make
function _get_cflags_from_make(target, sdkdir)
    local key = target:plat() .. target:arch()
    local cflags = memcache.get2("linux.driver", key, "cflags")
    local ldflags_o = memcache.get2("linux.driver", key, "ldflags_o")
    local ldflags_ko = memcache.get2("linux.driver", key, "ldflags_ko")
    if cflags == nil then
        local make = assert(find_tool("make"), "make not found!")
        local tmpdir = os.tmpfile() .. ".dir"
        local makefile = path.join(tmpdir, "Makefile")
        local stubfile = path.join(tmpdir, "stub.c")
        io.writefile(makefile, "obj-m := stub.o")
        io.writefile(stubfile, [[
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Ruki");
MODULE_DESCRIPTION("A simple Hello World Module");
MODULE_ALIAS("a simplest module");

int hello_init(void) {
    printk(KERN_INFO "Hello World\n");
    return 0;
}

void hello_exit(void) {
    printk(KERN_INFO "Goodbye World\n");
}

module_init(hello_init);
module_exit(hello_exit);
        ]])
        local argv = {"-C", sdkdir, "V=1", "M=" .. tmpdir, "modules"}
        if target:is_plat("cross") then
            -- e.g.	$(MAKE) -C $(KERN_DIR) V=1 ARCH=arm64 CROSS_COMPILE=/mnt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- M=$(PWD) modules
            local arch
            if target:is_arch("arm", "armv7") then
                arch = "arm"
            elseif target:is_arch("arm64", "arm64-v8a") then
                arch = "arm64"
            end
            assert(arch, "unknown arch(%s)!", target:arch())
            local cc = target:tool("cc")
            local cross = cc:gsub("%-gcc$", "-")
            table.insert(argv, "ARCH=" .. arch)
            table.insert(argv, "CROSS_COMPILE=" .. cross)
        end
        local result, errors = try {function () return os.iorunv(make.program, argv, {curdir = tmpdir}) end}
        if result then
            for _, line in ipairs(result:split("\n", {plain = true})) do
                if line:endswith("stub.c") then
                    for _, cflag in ipairs(line:split("%s+")) do
                        if cflag:startswith("-f") or cflag:startswith("-m")
                        or (cflag:startswith("-W") and not cflag:startswith("-Wp,-MMD,"))
                        or (cflag:startswith("-D") and not cflag:startswith("-DKBUILD_")) then
                            cflags = cflags or {}
                            table.insert(cflags, cflag)
                        end
                    end
                end
                local ldflags = line:match("%-ld (.+) %-o ") or line:match("ld (.+) %-o ")
                if ldflags then
                    local ko = ldflags:find("-T ", 1, true)
                    for _, ldflag in ipairs(ldflags:split("%s+")) do
                        if ko then
                            if ldflag:startswith("--build-id=") or ldflag:startswith("-T ") then
                                break
                            end
                            -- e.g. aarch64-linux-gnu-ld -r -EL  -maarch64elf --build-id=sha1  -T scripts/module.lds -o hello.ko hello.o hello.mod.o
                            ldflags_ko = ldflags_ko or {}
                            table.insert(ldflags_ko, ldflag)
                        else
                            -- e.g. aarch64-linux-gnu-ld -EL  -maarch64elf   -r -o hello.o xxx.o
                            ldflags_o = ldflags_o or {}
                            table.insert(ldflags_o, ldflag)
                        end
                    end
                end
                if cflags and ldflags_o and ldflags_ko then
                    break
                end
            end
        else
            if option.get("diagnosis") then
                print("rule(platform.linux.driver): cannot get cflags from make!")
                print(errors)
            end
        end
        os.tryrm(tmpdir)
        memcache.set2("linux.driver", key, "cflags", cflags or false)
    end
    return cflags or nil, ldflags_o or nil, ldflags_ko or nil
end

function load(target)
    -- we need only need binary kind, because we will rewrite on_link
    target:set("kind", "binary")
    target:set("extension", ".ko")

    -- get and save linux-headers sdk
    local linux_headers = _get_linux_headers_sdk(target)
    target:data_set("linux.driver.linux_headers", linux_headers)

    -- check compiler, we must use gcc
    assert(target:has_tool("cc", "gcc"), "we must use gcc compiler!")

    -- check rules
    for _, rulename in ipairs({"mode.release", "mode.debug", "mode.releasedbg", "mode.minsizerel", "mode.asan", "mode.tsan"}) do
        assert(not target:rule(rulename), "target(%s) is linux driver module, it need not rule(%s)!", target:name(), rulename)
    end

    -- add includedirs
    local sdkdir = linux_headers.sdkdir
    local includedir = linux_headers.includedir
    local archsubdir
    if target:is_arch("x86_64", "i386") then
        archsubdir = path.join(sdkdir, "arch", "x86")
    elseif target:is_arch("arm", "armv7") then
        archsubdir = path.join(sdkdir, "arch", "arm")
    elseif target:is_arch("arm64", "arm64-v8a") then
        archsubdir = path.join(sdkdir, "arch", "arm64")
    else
        raise("rule(platform.linux.driver): unsupported arch(%s)!", target:arch())
    end
    assert(archsubdir, "unknown arch(%s) for linux driver modules!", target:arch())
    local gcc_includedir = _get_gcc_includedir(target)
    if gcc_includedir then
        target:add("sysincludedirs", gcc_includedir)
    end
    target:add("includedirs", path.join(archsubdir, "include"))
    target:add("includedirs", path.join(archsubdir, "include", "generated"))
    target:add("includedirs", includedir)
    target:add("includedirs", path.join(archsubdir, "include", "uapi"))
    target:add("includedirs", path.join(archsubdir, "include", "generated", "uapi"))
    target:add("includedirs", path.join(includedir, "uapi"))
    target:add("includedirs", path.join(includedir, "generated", "uapi"))
    target:add("cflags", "-include " .. path.join(includedir, "linux", "kconfig.h"), {force = true})
    target:add("cflags", "-include " .. path.join(includedir, "linux", "compiler_types.h"), {force = true})
    -- we need disable includedirs from add_packages("linux-headers")
    target:pkg("linux-headers"):set("includedirs", nil)
    target:pkg("linux-headers"):set("sysincludedirs", nil)

    -- add compilation flags
    target:add("defines", "KBUILD_MODNAME=\"" .. target:name() .. "\"")
    for _, sourcefile in ipairs(target:sourcefiles()) do
        target:fileconfig_set(sourcefile, {defines = "KBUILD_BASENAME=\"" .. path.basename(sourcefile) .. "\""})
    end
    local cflags, ldflags_o, ldflags_ko = _get_cflags_from_make(target, sdkdir)
    if cflags then
        target:add("cflags", cflags, {force = true})
        target:data_set("linux.driver.ldflags_o", ldflags_o)
        target:data_set("linux.driver.ldflags_ko", ldflags_ko)
    end
end

function link(target, opt)
    local targetfile  = target:targetfile()
    local dependfile  = target:dependfile(targetfile)
    local objectfiles = target:objectfiles()
    depend.on_changed(function ()

        -- trace
        progress.show(opt.progress, "${color.build.object}linking.$(mode) %s", targetfile)

        -- get module scripts
        local modpost, ldscriptfile
        local linux_headers = target:data("linux.driver.linux_headers")
        if linux_headers then
            modpost = path.join(linux_headers.sdkdir, "scripts", "mod", "modpost")
            ldscriptfile = path.join(linux_headers.sdkdir, "scripts", "module.lds")
        end
        assert(modpost and os.isfile(modpost), "scripts/mod/modpost not found!")
        assert(ldscriptfile and os.isfile(ldscriptfile), "scripts/module.lds not found!")

        -- get ld
        local ld = target:tool("ld")
        assert(ld, "ld not found!")
        ld = ld:gsub("gcc$", "ld")
        ld = ld:gsub("g%+%+$", "ld")

        -- link target.o
        local argv = {}
        local ldflags_o = target:data("linux.driver.ldflags_o")
        if ldflags_o then
            table.join2(argv, ldflags_o)
        end
        local targetfile_o = target:objectfile(targetfile)
        table.join2(argv, "-o", targetfile_o)
        table.join2(argv, objectfiles)
        os.mkdir(path.directory(targetfile_o))
        os.vrunv(ld, argv)

        -- generate target.mod
        local targetfile_mod = targetfile_o:gsub("%.o$", ".mod")
        io.writefile(targetfile_mod, table.concat(objectfiles, " ") .. "\n\n")

        -- generate .sourcename.o.cmd
        -- we need only touch an empty file, otherwise modpost command will raise error.
        for _, objectfile in ipairs(objectfiles) do
            local objectdir = path.directory(objectfile)
            local objectname = path.filename(objectfile)
            local cmdfile = path.join(objectdir, "." .. objectname .. ".cmd")
            io.writefile(cmdfile, "")
        end

        -- generate target.mod.c
        local orderfile = path.join(path.directory(targetfile_o), "modules.order")
        local symversfile = path.join(path.directory(targetfile_o), "Module.symvers")
        argv = {"-m", "-a", "-o", symversfile, "-e", "-N", "-T", "-"}
        io.writefile(orderfile, targetfile_o .. "\n")
        os.vrunv(modpost, argv, {stdin = orderfile})

        -- compile target.mod.c
        local targetfile_mod_c = targetfile_o:gsub("%.o$", ".mod.c")
        local targetfile_mod_o = targetfile_o:gsub("%.o$", ".mod.o")
        local compinst = target:compiler("cc")
        if option.get("verbose") then
            print(compinst:compcmd(targetfile_mod_c, targetfile_mod_o, {target = target, rawargs = true}))
        end
        assert(compinst:compile(targetfile_mod_c, targetfile_mod_o, {target = target}))

        -- link target.ko
        argv = {}
        local ldflags_ko = target:data("linux.driver.ldflags_ko")
        if ldflags_ko then
            table.join2(argv, ldflags_ko)
        end
        local targetfile_o = target:objectfile(targetfile)
        table.join2(argv, "--build-id=sha1", "-T", ldscriptfile, "-o", targetfile, targetfile_o, targetfile_mod_o)
        os.mkdir(path.directory(targetfile))
        os.vrunv(ld, argv)

    end, {dependfile = dependfile, lastmtime = os.mtime(target:targetfile()), files = objectfiles})
end
