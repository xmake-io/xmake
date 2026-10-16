-- Functions in an includes file can compose existing description APIs.
function example_console(name, ...)
    interp_save_scope()
    target(name)
        set_kind("binary")
        add_files(...)
        set_warnings("all")
    target_end()
    interp_restore_scope()
end

-- The includes file calls this project-defined function after defining the helper.
example_configure_targets()
