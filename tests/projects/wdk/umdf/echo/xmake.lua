
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- enable unicode
add_defines("_UNICODE", "UNICODE")

-- add target
target("echo")

    -- add rules
    add_rules("wdk.umdf.driver")

    -- add files
    add_files("driver/*.c") 

    -- add includedirs
    add_includedirs("exe")

-- add target
target("app")

    -- add rules
    add_rules("wdk.umdf.binary")

    -- add files
    add_files("exe/*.cpp") 

