set_project("mimalloc")
add_rules("mode.release", "mode.debug")

set_warnings("all")
set_languages("c99")

target("mimalloc")
    set_kind("$(kind)")
    add_includedirs("mimalloc/include", {public = true})
    add_defines("XM_CONFIG_API_HAVE_MIMALLOC", {public = true})

    add_files("mimalloc/src/alloc.c")
    add_files("mimalloc/src/alloc-aligned.c")
    add_files("mimalloc/src/alloc-posix.c")
    add_files("mimalloc/src/arena.c")
    add_files("mimalloc/src/bitmap.c")
    add_files("mimalloc/src/heap.c")
    add_files("mimalloc/src/init.c")
    add_files("mimalloc/src/libc.c")
    add_files("mimalloc/src/options.c")
    add_files("mimalloc/src/os.c")
    add_files("mimalloc/src/page.c")
    add_files("mimalloc/src/random.c")
    add_files("mimalloc/src/segment.c")
    add_files("mimalloc/src/segment-map.c")
    add_files("mimalloc/src/stats.c")
    add_files("mimalloc/src/prim/prim.c")

    -- override malloc
    if is_plat("macosx") then
        add_files("mimalloc/src/prim/osx/alloc-override-zone.c")
        add_defines("MI_OSX_ZONE=1", "MI_OSX_INTERPOSE=1")
    end
    add_cflags("-fno-builtin-malloc", {tools = {"gcc", "clang", "gxx", "clangxx"}})

    -- fast atomics
    if is_plat("macosx", "iphoneos") and is_arch("arm64") then
        add_cflags("-Xarch_arm64;-march=armv8.1-a")
    elseif is_plat("windows") then
        add_cflags("cl:/arch:armv8.1")
    elseif is_arch("arm64") then
        add_cflags("-march=armv8.1-a", {tools = {"gcc", "clang", "gxx", "clangxx"}})
    end

    add_defines("MI_SKIP_COLLECT_ON_EXIT=1")
    if is_plat("windows") and is_kind("static") then
        add_defines("MI_WIN_USE_FIXED_TLS=1")
    end
    if is_plat("mingw") then
        add_defines("_WIN32_WINNT=0x600")
    end

    if is_plat("windows", "mingw") then
        add_syslinks("psapi", "shell32", "user32", "advapi32", "bcrypt", {public = true})
    else
        add_syslinks("pthread", {public = true})
    end
