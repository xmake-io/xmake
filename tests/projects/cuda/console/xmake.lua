add_rules("mode.debug", "mode.release")

target("cuda_console")
    set_kind("binary")
    add_includedirs("inc")
    add_files("src/*.cu")

    -- generate SASS code for each SM architecture
    add_cugencodes("sm_75", "sm_80", "sm_89", "sm_90", "sm_100")

    -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    add_cugencodes("compute_100")

