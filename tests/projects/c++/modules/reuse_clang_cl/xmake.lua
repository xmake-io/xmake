add_rules("mode.debug", "mode.release")
set_languages("c++20")

target("producer")
    set_kind("static")
    add_files("src/sample.cppm", {public = true})
    add_files("src/part.cpp", "src/sample.cpp", {public = true})

for _, name in ipairs({"consumer_a", "consumer_b", "different_language", "different_define"}) do
    target(name)
        set_kind("binary")
        add_deps("producer")
        add_files("src/main.cpp")
        add_sysincludedirs("src/include")
        if name == "different_language" then
            set_languages("c++23")
        elseif name == "different_define" then
            set_policy("build.c++.modules.reuse.strict", true)
            add_defines("DIFFERENT_MODULE_DEFINE")
        end
end

target("moduleonly_producer")
    set_kind("moduleonly")
    add_files("src/sample.cppm", "src/part.cpp", "src/sample.cpp", {public = true})

target("moduleonly_consumer")
    set_kind("binary")
    add_deps("moduleonly_producer")
    add_sysincludedirs("src/include")
    add_files("src/main.cpp")
