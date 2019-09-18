
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- define target
target("${TARGETNAME}")

    -- set kind
    set_kind("shared")

    -- add include dirs
    add_includedirs("inc")

    -- generate relocatable device code for device linker of dependents.
    -- if __device__ or __global__ functions will be called cross file,
    -- or dynamic parallelism will be used,
    -- this instruction should be opted in.
    -- add_cuflags("-rdc=true")

    -- add files
    add_files("src/**.cu")

    -- generate SASS code for SM architecture of current host
    add_cugencodes("native")

    -- generate PTX code for the virtual architecture to guarantee compatibility
    add_cugencodes("compute_30")

    -- -- generate SASS code for each SM architecture
    -- add_cugencodes("sm_30", "sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70", "sm_75")

    -- -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    -- add_cugencodes("compute_75")

${FAQ}
