add_rules("mode.debug", "mode.release")

target("cuda_console")
    set_kind("binary")
    add_includedirs("inc")
    add_files("src/*.cu")

    -- generate SASS code for each SM architecture
    add_cugencodes("sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70", "sm_75")

    -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    add_cugencodes("compute_75")


