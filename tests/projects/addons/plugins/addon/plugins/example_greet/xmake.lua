task("example_greet")
    set_category("plugin")
    set_menu {
        usage = "xmake example_greet [options]",
        description = "Greet someone from the example addon.",
        options = {{'n', "name", "kv", "world", "Set the name."}}
    }
    on_run("main")
