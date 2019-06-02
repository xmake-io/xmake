
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- add helper function add_cugencode
includes('add_cugencode.lua')

-- define target
target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.cu")

    -- generate SASS code for SM architecture of current host
    add_cugencode("native")

    -- generate PTX code for the virtual architecture to guarantee compatibility
    add_cugencode("compute_30")

    -- -- generate SASS code for each SM architecture
    -- add_cugencode("sm_30", "sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70", "sm_75")

    -- -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    -- add_cugencode("compute_75")