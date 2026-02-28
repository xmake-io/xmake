add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("static")
    add_files("src/**.cu")
    add_includedirs("inc")

    -- generate SASS code for SM architecture of current host
    add_cugencodes("native")

    -- generate PTX code for the virtual architecture to guarantee compatibility
    add_cugencodes("compute_75")

    -- -- generate SASS code for each SM architecture
    -- add_cugencodes("sm_75", "sm_80", "sm_89", "sm_90", "sm_100")

    -- -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    -- add_cugencodes("compute_100")

${FAQ}
