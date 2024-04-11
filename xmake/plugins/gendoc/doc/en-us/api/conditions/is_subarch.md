---
isapi: true
key: is_subarch
name: is_subarch
page: api/conditions.html
---

### ${anchor:is_subarch}

Determine the architecture of the current host subsystem environment

`bool is_arch(string arch, ...)`

At present, it is mainly used for the detection of the architecture under the subsystem environment such as cygwin and msys2 on the windows system. The msvc tool chain is usually used on the windows compilation platform, and the architecture is x64, x86.
In the msys/cygwin subsystem environment, the compiler architecture defaults to x86_64/i386, which is different.

We can also quickly view the current subsystem architecture by executing `xmake l os.subarch`.

#### Support version: >= 2.0.1

#### See also

${link:is_arch}, ${link:is_os}, ${link:is_plat}
