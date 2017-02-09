-- the debug mode
if is_mode("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if is_mode("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
target("console_c")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 

    set_config_h("$(buildir)/config.h")
    set_config_h_prefix("TEST")

    add_cfunc(nil,          "POLL",  nil,       {"sys/poll.h"},     "poll")
    add_cfunc("libc",       nil,    nil,        {"sys/select.h"},   "select")
    add_cfunc("pthread",    nil,    "pthread",  "pthread.h",        "pthread_create")

