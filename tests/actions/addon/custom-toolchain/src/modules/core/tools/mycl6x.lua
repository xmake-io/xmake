-- our compiler behaves like gcc, it's just a wrapper of the host one
inherit("core.tools.gcc")

-- the marker of this module, the tests use it to check that it comes from the addon
function greeting()
    return "hello from the custom toolchain addon"
end
