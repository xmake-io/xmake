
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("qt_demo")

    -- add rules
    add_rules("qt.static")

    -- add headers
    add_headers("src/*.h")

    -- add files
    add_files("src/*.cpp") 

    -- add frameworks
    add_frameworks("QtGui")
