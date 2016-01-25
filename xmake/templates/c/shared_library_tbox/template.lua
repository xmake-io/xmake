-- set description
set_description("The Shared Library (tbox)")

-- set project directory
set_projectdir("project")

-- add macros
add_macros("targetname", "$(targetname)")

-- add macro files
add_macrofiles("xmake.lua")
add_macrofiles("src/$(targetname)_demo/main.c")
add_macrofiles("src/$(targetname)_demo/xmake.lua")
add_macrofiles("src/$(targetname)/xmake.lua")

-- add move directories
add_movedirs("src/_library", "src/$(targetname)")
add_movedirs("src/_demo", "src/$(targetname)_demo")

-- add copy directories
add_copydirs("$(packagesdir)/tbox.pkg", "pkg/tbox.pkg")
add_copydirs("$(packagesdir)/base.pkg", "pkg/base.pkg")
