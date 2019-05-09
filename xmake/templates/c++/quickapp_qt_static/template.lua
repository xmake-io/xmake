-- set name
set_name("quickapp_qt_static")

-- set description
set_description("The Quick Application (Qt/Static)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")

