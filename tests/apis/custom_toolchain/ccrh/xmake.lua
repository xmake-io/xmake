local project_name = "r7f701583"
set_project(project_name)
set_policy("check.auto_ignore_flags", false)

add_rules("mode.debug", "mode.release")

add_moduledirs("xmake/modules")
add_toolchaindirs("xmake/toolchains")

set_toolchains("ccrh")

target("add", function()
    set_kind("static")
    add_files("src/add.c")

    set_languages("c99")
    add_cflags("-Xcpu=g3kh", "-Xmsg_lang=english", "-Xcharacter_set=utf8")
end)

target(project_name, function()
    set_kind("binary")
    add_deps("add")
    add_files("src/main.c")
    add_files("src/*.asm")

    set_languages("c99")
    add_asflags("-Xcpu=g3kh", "-Xmsg_lang=english", "-Xcharacter_set=utf8")
    add_cflags("-Xcpu=g3kh", "-Xmsg_lang=english", "-Xcharacter_set=utf8")
    local ld_script = path.absolute(".") .. "/src/r7f701583.ld"
    add_ldflags("-sub=" .. ld_script, "-nooptimize", "-form=absolute", "-show=symbol")

    on_config(function(target)
        local rlink_path = target:tool("ld")
        local ccrh_bin_dir = path.directory(rlink_path)
        local ccrh_lib_dir = path.join(path.directory(ccrh_bin_dir), "lib")
        local out_dir = target:targetdir()

        local sys_lib = "-library="
            .. ccrh_lib_dir
            .. "/v850e3v5/rhs8n.lib"
            .. " "
            .. "-library="
            .. ccrh_lib_dir
            .. "/v850e3v5/libmalloc.lib"
        target:add("ldflags", sys_lib)

        target:add("ldflags", "-list=" .. out_dir .. "/" .. project_name .. ".list")
    end)

    after_build(function(target)
        local rlink_path = target:tool("ld")
        local abs_file = target:targetfile()
        local out_dir = target:targetdir()

        print("Generating .bin .hex .srec files")

        gen_bin_cmd = rlink_path
            .. " "
            .. abs_file
            .. ".abs -form=binary -output="
            .. out_dir
            .. "/"
            .. project_name
            .. ".bin"
        os.exec(gen_bin_cmd)

        gen_hex_cmd = rlink_path
            .. " "
            .. abs_file
            .. ".abs -form=hexadecimal -output="
            .. out_dir
            .. "/"
            .. project_name
            .. ".hex"
        os.exec(gen_hex_cmd)

        gen_srec_cmd = rlink_path
            .. " "
            .. abs_file
            .. ".abs -form=stype -output="
            .. out_dir
            .. "/"
            .. project_name
            .. ".srec"
        os.exec(gen_srec_cmd)

        os.mv(abs_file .. ".abs", abs_file .. ".elf")
    end)
end)
