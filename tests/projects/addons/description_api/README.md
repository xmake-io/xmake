# Description Api addon example

This directory is a complete user project with an addon and a local package repository.
Use a current Xmake dev build with addon support, Git, and a native C compiler.

```sh
xmake -y
xmake run hello
```

Expected program output: `hello from a custom scope (2 tags)`.

- `xmake.lua`: the user project, declaring its repository and required addon.
- `repo/addons/e/example-description-api/xmake.lua`: a package recipe with `set_kind("addon")`.
- `addon/addon.lua`: the addon manifest; payloads are under this directory.
- `src/main.c`: the user's application.

The first build automatically installs the addon from `addon/` through the local recipe.
No manual `xmake addon --install` is needed. This is automatic local installation, not
an HTTP download. A published recipe can use `add_urls` and `add_versions` instead.
The local source recipe is installed as `latest` and the project generates
`xmake-addons.lock`; a release recipe supplies a version and checksum.

The addon is installed in Xmake's user-level addon directory. After editing its payloads,
run `xmake addon --install -y --force example-description-api` from this project, then rebuild.
Changing only the user project's settings needs just another `xmake` invocation.
Remove the sample addon when finished with `xmake addon --remove example-description-api`.
Use a separate `XMAKE_GLOBALDIR` if you want to keep these examples out of your normal
addon registry. Set this environment variable before running any of the commands above.

The project defines `example_configure_profiles()` before the addon includes file is loaded.
The includes file registers its extension APIs/helpers and then calls this function in
the description domain. This is an explicit contract of this example addon, not a new
Xmake lifecycle hook. It lets the initial project scan finish while the addon is still
missing. Calling an addon-defined description API directly after an unresolved includes
file can fail on that first scan. Capture the user project's script directory before
entering the addon includes file so source paths still refer to the user project.
