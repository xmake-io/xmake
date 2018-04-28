
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("echo")

    -- add rules
    add_rules("wdk.driver.umdf")

    -- add files
    add_files("driver/*.c") 

-- add target
target("app")

    -- add deps
    add_deps("echo")

    -- add rules
    add_rules("wdk.binary")

    -- add files
    add_files("exe/*.cpp") 

