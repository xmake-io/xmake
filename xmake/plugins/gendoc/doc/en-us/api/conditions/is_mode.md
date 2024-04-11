---
isapi: true
key: is_mode
name: is_mode
page: api/conditions.html
---

### ${anchor:is_mode}

Is the current compilation mode

`bool is_mode(string mode, ...)`

You can use this api to check the configuration command: `xmake f -m debug`

The compilation mode is not builtin mode for xmake, so you can set the mode value by yourself.

We often use these configuration values: `debug`, `release`, `profile`, etc.

```lua
-- if the current compilation mode is debug?
if ${link:is_mode}("debug") then

    -- add macro: DEBUG
    ${link:add_defines}("DEBUG")

    -- enable debug symbols
    ${link:set_symbols}("debug")

    -- disable optimization
    ${link:set_optimize}("none")

end

-- if the current compilation mode is release or profile?
if ${link:is_mode}("release", "profile") then

    if ${link:is_mode}("release") then

        -- mark symbols visibility as hidden
        ${link:set_symbols}("hidden")

        -- strip all symbols
        ${link:set_strip}("all")

        -- fomit frame pointer
        ${link:add_cxflags}("-fomit-frame-pointer")
        ${link:add_mxflags}("-fomit-frame-pointer")

    else

        -- enable debug symbols
        ${link:set_symbols}("debug")

    end

    -- add vectorexts
    ${link:add_vectorexts}("sse2", "sse3", "ssse3", "mmx")
end
```

#### Support version: >= 2.0.1

#### See also

${link:is_config}, ${link:var_mode}, ${link:os_is_mode}
