task("demo_hello")
    set_category("plugin")
    on_run("main")
    set_menu {
        usage = "xmake demo_hello [options]",
        description = "Say hello from the demo addon.",
        options = {
            {'n', "name", "kv", nil, "Set the name to say hello to."}
        }
    }
