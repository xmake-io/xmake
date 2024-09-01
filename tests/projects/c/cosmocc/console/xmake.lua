add_rules("mode.debug", "mode.release")

add_requires("cosmocc")

-- TODO, we should add envs to toolchains/cosmocc
if is_subhost("windoows") then
    add_requires("msys2")
    add_packages("msys2")
end

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("@cosmocc")

