
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("${TARGETNAME}")

    -- add rules
    add_rules("qt.widgetapp")

    -- add headerfiles
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp") 
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h") 

${FAQ}
