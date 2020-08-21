add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    set_kind("binary")
    add_files("src/*.cu")

    -- generate relocatable device code for device linker of dependents.
    -- if __device__ or __global__ functions will be called cross file,
    -- or dynamic parallelism will be used,
    -- this instruction should be opted in.
    -- add_cuflags("-rdc=true")

    -- generate SASS code for SM architecture of current host
    add_cugencodes("native")

    -- generate PTX code for the virtual architecture to guarantee compatibility
    add_cugencodes("compute_35")

    -- -- generate SASS code for each SM architecture
    -- add_cugencodes("sm_35", "sm_37", "sm_50", "sm_52", "sm_60", "sm_61", "sm_70", "sm_75")

    -- -- generate PTX code from the highest SM architecture to guarantee forward-compatibility
    -- add_cugencodes("compute_75")

${FAQ}
