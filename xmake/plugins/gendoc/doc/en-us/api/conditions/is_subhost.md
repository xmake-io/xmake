---
isapi: true
key: is_subhost
name: is_subhost
page: api/conditions.html
---

### ${anchor:is_subhost}

Determine the subsystem environment of the current host

`bool is_subhost(string subhost, ...)`

At present, it is mainly used for detection of cygwin, msys2 and other subsystem environments on windows systems. If you run xmake in the msys2 shell environment, then `is_subhost("windows")` will return false, and `is_host("windows")` It will still return true.

Currently supported subsystems:

* "msys"
* "cygwin"

Configuration example:

```lua
if ${link:is_subhost}("msys", "cygwin") then
    -- Currently in the shell environment of msys2/cygwin
end
```

We can also quickly check the current subsystem platform by executing `xmake l os.subhost`.

> ⚠ **It may also support other subsystem environments under linux and macos systems later, if they exist.**

#### Support version: >= 2.3.1 (?)

#### See also

${link:is_host}, ${link:var_subhost}, ${link:os_is_subhost}
