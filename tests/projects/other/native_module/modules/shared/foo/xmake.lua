add_rules("mode.debug", "mode.release")

if xmake.luajit() then
    add_requires("luajit", {alias = "lua"})
else
    add_requires("lua 5.4")
end

target("foo")
    add_rules("module.shared")
    add_files("src/foo.c")
    add_packages("lua")

