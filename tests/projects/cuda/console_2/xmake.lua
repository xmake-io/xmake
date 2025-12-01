add_rules("mode.debug", "mode.release")

-- generate PTX code for the virtual architecture to guarantee compatibility
add_cugencodes("compute_75")

target("bin")
    set_kind("binary")
    add_includedirs("inc")
    add_files("src/*.cu")
