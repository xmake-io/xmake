---
isapi: true
key: os_cp
name: os.cp
page: api/builtin_modules/os.html
---

### ${anchor:os_cp}

Copy files or directories

`nil os.cp(string src, string dst, table opt)`

The behavior is similar to the `cp` command in the shell, supporting path wildcard matching (using lua pattern matching), support for multi-file copying, and built-in variable support.

Valid fields for `opt` are:

* `string rootdir`
* `bool symlink`

e.g:

```lua
${link:os_cp}("$(scriptdir)/*.h", "$(buildir)/inc")
${link:os_cp}("$(projectdir)/src/test/**.h", "$(buildir)/inc")
```

The above code will: all the header files in the current `xmake.lua` directory, the header files in the project source test directory are all copied to the `$(buildir)` output directory.

Among them `$(scriptdir)`, `$(projectdir)` These variables are built-in variables of xmake. For details, see the related documentation of [built-in variables](#built-in variables).

The matching patterns in `*.h` and `**.h` are similar to those in [add_files](#targetadd_files), the former is a single-level directory matching, and the latter is a recursive multi-level directory matching.

This interface also supports `recursive replication' of directories, for example:

```lua
-- Recursively copy the current directory to a temporary directory
${link:os_cp}("$(curdir)/test/", "$(tmpdir)/test")
```

The copy at the top will expand and copy all files to the specified directory, and lose the source directory hierarchy. If you want to copy according to the directory structure that maintains it, you can set the rootdir parameter:

```lua
${link:os_cp} ("src/**.h", "/tmp/", {rootdir="src"})
```

The above script can press the root directory of `src` to copy all sub-files under src in the same directory structure.

> ⚠ **Try to use the `os.cp` interface instead of `os.run("cp ..")`, which will ensure platform consistency and cross-platform build description.**

Under 2.5.7, the parameter `{symlink = true}` is added to keep the symbolic link when copying files.

```lua
${link:os_cp}("/xxx/foo", "/xxx/bar", {symlink = true})
```

#### Support version: >= 2.0.1

#### See also

${link:os_trycp}
