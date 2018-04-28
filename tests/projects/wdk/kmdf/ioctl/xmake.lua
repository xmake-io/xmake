
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("nonpnp")

    -- add rules
    add_rules("wdk.driver.kmdf")

    -- add files
    add_files("driver/*.c") 

-- add target
target("app")

    -- add deps
    add_deps("nonpnp")

    -- add rules
    add_rules("wdk.binary")

    -- add files
    add_files("exe/*.c") 

