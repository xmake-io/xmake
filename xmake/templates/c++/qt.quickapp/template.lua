-- set name
set_name("qt.quickapp")

-- set description
set_description("The Quick Application (Qt)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")

