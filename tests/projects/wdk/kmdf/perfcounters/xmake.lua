
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("kcs")

    -- add rules
    add_rules("wdk.kmdf.driver")

    -- add files
    add_files("*.c", "*.rc", "*.man") 

