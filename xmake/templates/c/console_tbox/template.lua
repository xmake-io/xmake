-- set description
set_description("The Console Program (tbox)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("src/xmake.lua")

-- set create script
on_create(function ()

    -- show tips
    print("please put tbox.pkg into pkg before building it!")
end)
