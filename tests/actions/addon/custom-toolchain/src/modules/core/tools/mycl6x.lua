-- the tool module of the my-c6000 toolchain
--
-- @note our compiler behaves like gcc, it's just a wrapper of the host one, so we only
-- inherit it here, a real one implements the tool interfaces itself, e.g. `init`,
-- `nf_define`, `compargv`, `link`, @see tests/apis/custom_toolchain
--
inherit("core.tools.gcc")

-- init it
function init(self)
    self:set("cxflags", "-DMY_C6000_TOOL")
end
