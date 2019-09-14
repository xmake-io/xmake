-- set name
set_name("tbox.static")

-- set description
set_description("The Static Library (tbox)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")
add_macrofiles("src/_demo/main.c")
add_macrofiles("src/_demo/xmake.lua")
add_macrofiles("src/_library/xmake.lua")

-- set create script
on_create(function ()

    -- rename target directory
    os.mv("src/_library", "src/$(targetname)")
    os.mv("src/_demo", "src/$(targetname)_demo")
end)
