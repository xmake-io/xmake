add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("binary")
    add_files("src/*.cu")

    -- generate SASS code for SM architecture of current host
    add_cugencodes("native")

    -- generate PTX code for the virtual architecture to guarantee compatibility
    add_cugencodes("compute_35")

    -- -- generate SASS code for each SM architecture
    -- add_cugencodes("sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70", "sm_75")

    -- -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    -- add_cugencodes("compute_75")

${FAQ}
