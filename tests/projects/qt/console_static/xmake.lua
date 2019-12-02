
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- add target
target("qt_console")

    -- add rules
    add_rules("qt.console")

    -- add files
    add_files("src/*.cpp")

