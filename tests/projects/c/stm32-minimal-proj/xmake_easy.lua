-- set_xmakever("2.6.4")

add_rules("mode.debug", "mode.release")
set_plat("cross")

toolchain("arm-gcc")
    local tool_path = "/Applications/ARM/"
    set_kind("cross")
    set_description("Stm32 Arm Embedded Compiler")
    set_sdkdir(tool_path)
    set_toolset("cc", "arm-none-eabi-gcc")
    -- set_toolset("cxx", "arm-none-eabi-g++")
    set_toolset("ld", "arm-none-eabi-ld")

    on_load(function (toolchain)
        toolchain:add("cxflags", "-fno-common", "-ffreestanding", "-O0", "-gdwarf-2", 
        "-g3", "-Wall", "-Werror", 
        "-mcpu=cortex-m3", "-mthumb", "-nostartfiles") 
        toolchain:add("ldflags", "-Tsrc/main.ld", {force=true})
    end)
toolchain_end()

set_toolchains("arm-gcc")

target("minimal-proj")
    set_kind("binary")
    add_files("src/*.c")
    -- add_cxflags("-fno-common", "-ffreestanding", "-O0", "-gdwarf-2", 
    -- "-g3", "-Wall", "-Werror", 
    -- "-mcpu=cortex-m3", "-mthumb", "-nostartfiles")
    -- add_ldflags("-Tsrc/main.ld", {force=true})

    after_build(function (target)
        print("after_build")
	    local out = target:targetfile() or ""
        local bin_out = " build/minimal-proj.bin"
        print(string.format("%s => %s", out, bin_out))
        os.exec("arm-none-eabi-objcopy -Obinary "..out.." "..bin_out)
        os.exec("qemu-system-arm -M stm32-p103 -nographic -kernel"..bin_out)
    end)

-- If you want to known more usage about xmake, please see https://xmake.io
-- Reference Project:
-- https://github.com/xmake-io/xmake-docs/blob/master/zh-cn/about/who_is_using_xmake.md
-- https://github.com/idealvin/cocoyaxi/blob/master/src/xmake.lua
-- 
-- 
-- ## FAQ
--
-- You can enter the project directory firstly before building project.
--
--   $ cd projectdir
--
-- 1. How to build project?
--
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code
--    -- add debug and release modes
--    add_rules("mode.debug", "mode.release")
--
--    -- add macro defination
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "c++11")
--
--    -- set optimization: none, faster, fastest, smallest
--    set_optimize("fastest")
--
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add system link libraries
--    add_syslinks("z", "pthread")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--

