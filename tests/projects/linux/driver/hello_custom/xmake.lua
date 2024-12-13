option("linux-headers", {showmenu = true, description = "Set linux-headers path."})
target("hello")
    add_rules("platform.linux.module")
    add_files("src/*.c")
    set_values("linux.driver.linux-headers", "$(linux-headers)")

