
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- generate PTX code for the virtual architecture to guarantee compatibility
add_cugencodes("compute_30")

-- define target
target("bin")

    -- set kind
    set_kind("binary")

    add_cuflags("-rdc=true")

    add_includedirs("inc")

    -- add files
    add_files("src/*.cu")
