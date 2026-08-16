-- the addons which this project needs, they are installed automatically
add_addons("custom-include", "custom-rule", "custom-toolchain")

-- the option comes from the includes file of an addon
includes("@addon/custom-include/check")

target("hello")
    set_kind("binary")
    add_files("src/main.c")
    add_rules("@addon/custom-rule/hello")
    set_toolchains("@addon/custom-toolchain/my-c6000")
    if has_config("myoption") then
        add_defines("MYOPTION")
    end
