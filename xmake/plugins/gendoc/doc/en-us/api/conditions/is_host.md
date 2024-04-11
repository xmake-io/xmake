---
isapi: true
key: is_host
name: is_host
page: api/conditions.html
---

### ${anchor:is_host}

Is the current compilation host system

`bool is_host(string host, ...)`

Returns true if the current compilation host system is the one specified with *host*. Returns false otherwise.

Some compilation platforms can be built on multiple different operating systems, for example: android ndk (on linux, macOS and windows).

So, we can use this api to determine the current host operating system.

```lua
if ${link:is_host}("windows") then
    ${link:add_includedirs}("C:\\includes")
else
    ${link:add_includedirs}("/usr/includess")
end
```

Support hosts:

* "windows"
* "linux"
* "macosx"

We can also get it from ${link:var_host} [$(host)](/manual/builtin_variables?id=varhost) or ${link:os_host} [os.host](/manual/builtin_modules?id=oshost).

#### Support version: >= 2.1.4

#### See also

${link:is_arch}, ${link:is_os}, ${link:is_plat}, ${link:is_subhost}
