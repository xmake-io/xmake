-- set description
set_description("The Console Program (tbox)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("src/xmake.lua")

-- add copy directories
add_copydirs("$(packagesdir)/tbox.pkg", "pkg/tbox.pkg")
add_copydirs("$(packagesdir)/base.pkg", "pkg/base.pkg")
