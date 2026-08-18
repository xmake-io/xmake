-- @note `format` is a builtin plugin of xmake, we use it to test that an addon
-- is able to take over a builtin plugin
task("format")
    set_category("plugin")
    set_menu {usage = "xmake format", description = "Say hello instead of formatting.", options = {}}
    on_run("main")
