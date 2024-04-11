---
isapi: true
key: is_plat
name: is_plat
page: api/conditions.html
---

### ${anchor:is_plat}

Is the current compilation platform

`bool is_plat(string plat, ...)`

Returns true if the current compilation platform is the one specified with *plat*. Returns false otherwise.

You can use this api to check the configuration command: `xmake f -p iphoneos`

```lua
-- if the current platform is android
if ${link:is_plat}("android") then
    ${link:add_files}("src/xxx/*.c")
end

-- if the current platform is macosx or iphoneos
if ${link:is_plat}("macosx", "iphoneos") then
    ${link:add_frameworks}("Foundation")
end
```

Support platforms:

* "windows"
* "linux"
* "macosx"
* "android"
* "iphoneos"
* "watchos"

#### Support version: >= 2.0.1

#### See also

${link:is_arch}, ${link:is_host}, ${link:is_mode}, ${link:is_os}
