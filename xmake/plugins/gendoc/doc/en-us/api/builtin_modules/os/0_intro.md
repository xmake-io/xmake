---
isapi: false
key: os_intro
name: os
page: api/builtin_modules/os.html
---

## ${anchor:os_intro}

The system operation module belongs to the built-in module. It can be called directly by the script scope without using ${link:import}.

This module is also a native module of lua, and xmake has been extended to provide more practical interfaces.

> ⚠ **Only some readonly interfaces (for example: `os.getenv`, `os.arch`) in the os module can be used in the description scope. Other interfaces can only be used in the script domain, for example: `${link:os_cp}`, `os .rm`etc.**
