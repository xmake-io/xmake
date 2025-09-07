add_rules("mode.debug", "mode.release")

for i = 1, 30 do
    target("test" .. i)
        set_kind("binary")
        add_files("src/main.cpp")
end
