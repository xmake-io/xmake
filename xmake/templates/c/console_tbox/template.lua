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

    -- copy packages
    os.cp("$(packagesdir)/tbox.pkg", "pkg/tbox.pkg")
    os.cp("$(packagesdir)/base.pkg", "pkg/base.pkg")

end)
