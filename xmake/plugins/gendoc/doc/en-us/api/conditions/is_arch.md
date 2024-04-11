---
isapi: true
key: is_arch
name: is_arch
page: api/conditions.html
---

### ${anchor:is_arch}

Is the current compilation architecture

`bool is_arch(string arch, ...)`

Returns true if the current compilation architecture is the one specified with *arch*. Returns false otherwise.

You can use this api to check the configuration command: `xmake f -a armv7`

```lua
-- if the current architecture is x86_64 or i386
if ${link:is_arch}("x86_64", "i386") then
    ${link:add_files}("src/xxx/*.c")
end

-- if the current architecture is armv7 or arm64 or armv7s or armv7-a
if ${link:is_arch}("armv7", "arm64", "armv7s", "armv7-a") then
    -- ...
end
```

And you can also use the lua regular expression: `.*` to check all matched architectures.

```lua
-- if the current architecture is arm which contains armv7, arm64, armv7s and armv7-a ...
if ${link:is_arch}("arm.*") then
    -- ...
end
```

#### Support version: >= 2.0.1

#### See also

${link:is_host}, ${link:is_os}, ${link:is_plat}, ${link:is_subarch}
