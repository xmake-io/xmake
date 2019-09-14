-- set name
set_name("qt.widgetapp_static")

-- set description
set_description("The Widget Application (Qt/Static)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")

