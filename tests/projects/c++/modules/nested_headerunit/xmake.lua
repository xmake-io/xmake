add_rules("mode.debug", "mode.release")
set_languages("c++20")

for _, name in ipairs({"relative", "absolute"}) do
    target(name)
        set_kind("binary")
        add_includedirs(name == "relative" and "include" or path.join(os.scriptdir(), "include"))
        add_files("src/main.cpp")
        set_policy("build.c++.modules", true)
end
