task("hello_addon")
    set_category("plugin")
    set_menu {usage = "xmake hello_addon", description = "Say hello from the addon.",
              options = {{'n', "name", "kv", nil, "Set the name."}}}
    on_run("main")
