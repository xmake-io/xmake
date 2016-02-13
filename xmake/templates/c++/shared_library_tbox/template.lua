-- set description
set_description("The Shared Library (tbox)")

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
set_createscript(function ()

    -- rename target directory
    os.mv("src/_library", vformat("src/$(targetname)"))
    os.mv("src/_demo", vformat("src/$(targetname)_demo"))

    -- copy packages
    os.cp(vformat("$(packagesdir)/tbox.pkg"), "pkg/tbox.pkg")
    os.cp(vformat("$(packagesdir)/base.pkg"), "pkg/base.pkg")

end)
