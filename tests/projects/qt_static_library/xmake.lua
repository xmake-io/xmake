
-- add modes: debug and release 
add_rules("mode:debug", "mode:release")

-- add target
target("qt_demo")

    -- add rules
    add_rules("qt:static")

    -- add files
    add_files("src/*.cpp") 

