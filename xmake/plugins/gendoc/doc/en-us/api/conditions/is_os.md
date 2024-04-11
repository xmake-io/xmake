---
isapi: true
key: is_os
name: is_os
page: api/conditions.html
---

### ${anchor:is_os}

Is the current compilation target system

`bool is_os(string os, ...)`

Returns true if the target compilation os is the one specified with *os*. Returns false otherwise.

```lua
if ${link:is_os}("ios") then
    ${link:add_files}("src/xxx/*.m")
end
```

Valid input values are:

* "windows"
* "linux"
* "android"
* "macosx"
* "ios"

#### Support version: >= 2.0.1

#### See also

${link:is_arch}, ${link:is_host}, ${link:is_mode}, ${link:is_plat}
