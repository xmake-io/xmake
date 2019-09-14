-- set name
set_name("shared")

-- set description
set_description("The Shared Library")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")
