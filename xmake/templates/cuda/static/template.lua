-- set name
set_name("static")

-- set description
set_description("The Static Library")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")