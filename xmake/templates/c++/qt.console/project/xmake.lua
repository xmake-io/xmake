
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("${TARGETNAME}")

    -- add rules
    add_rules("qt.console")

    -- add files
    add_files("src/*.cpp") 

${FAQ}
