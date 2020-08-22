add_rules("mode.debug", "mode.release")

-- generate PTX code for the virtual architecture to guarantee compatibility
add_cugencodes("compute_30")

target("lib")
    set_kind("shared")
    add_files("src/lib.cu")
    add_includedirs("inc", {public = true})

target("bin")
    add_deps("lib")
    set_kind("binary")
    add_files("src/main.cu")
