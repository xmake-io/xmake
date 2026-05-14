add_moduledirs("$(projectdir)/test")
add_moduledirs("test")

task("foo")
    set_category("plugin")
    on_run(function()
        local modules = import("core.sandbox.module")
		for _, dir in ipairs(modules.directories()) do
			print(dir)
		end
    end)
    set_menu {
        usage = "xmake foo",
        description = "Print all modules"
    }