-- add rules
add_rules("mode.debug", "mode.release")

-- define target
target("cuda_console")

    -- set kind
    set_kind("binary")

    -- add include directories
    add_includedirs("inc")

    -- add files
    add_files("src/*.cu")

    -- generate SASS code for each SM architecture
    add_cugencodes("sm_30", "sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70")

    -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    add_cugencodes("compute_70")

    
