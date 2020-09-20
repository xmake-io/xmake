target("test")
    set_kind("binary")
    add_files("src/*.c")
    if is_plat("linux") then
        add_files("src/main_elf.S")
    else
        add_files("src/main.S")
    end
