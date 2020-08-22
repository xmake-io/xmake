add_rules("mode.debug", "mode.release")

-- generate PTX code for the virtual architecture to guarantee compatibility
add_cugencodes("compute_30")

target("lib")
    set_kind("static")
    add_cuflags("-rdc=true")
    add_includedirs("inc", {public = true})
    add_files("src/lib.cu")

target("bin")
    add_deps("lib")
    set_kind("binary")
    add_files("src/main.cu")
