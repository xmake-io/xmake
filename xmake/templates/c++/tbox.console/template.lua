-- set name
set_name("tbox.console")

-- set description
set_description("The Console Program (tbox)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("src/xmake.lua")

