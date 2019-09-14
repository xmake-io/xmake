-- set name
set_name("qt.console")

-- set description
set_description("The Console Program (Qt)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")

