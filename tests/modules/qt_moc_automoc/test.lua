import("rules.qt.moc.utils", {rootdir = os.programdir()})

function _with_temp_project(callback)
    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    local olddir = os.cd(tempdir)
    try
    {
        function ()
            callback(tempdir)
        end,
        finally
        {
            function (ok, errors)
                os.cd(olddir)
                os.tryrm(tempdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function _mock_target(opt)
    opt = opt or {}
    local data_store = {}
    local target = {}

    function target:headerfiles()
        return opt.headerfiles or {}
    end

    function target:sourcefiles()
        return opt.sourcefiles or {}
    end

    function target:values(name)
        if name == "qt.moc.macros" then
            return opt.macros
        end
    end

    function target:get(name)
        if name == "qt.moc.macros" then
            return opt.macros
        elseif name == "includedirs" then
            return opt.includedirs
        elseif name == "qt.moc.flags" then
            return opt.moc_flags
        end
    end

    function target:get_from(name, sources)
        if name ~= "includedirs" then
            return nil
        end
        if opt.on_get_from then
            opt.on_get_from(name, sources)
        end
        if opt.includedirs_sources then
            local vals = {}
            local srcs = {}
            for _, item in ipairs(opt.includedirs_sources) do
                table.insert(vals, item.dirs)
                table.insert(srcs, item.source)
            end
            return vals, srcs
        end
        if opt.includedirs and #opt.includedirs > 0 then
            return {opt.includedirs}, {"self"}
        end
        return nil
    end

    function target:rule()
        return nil
    end

    function target:data(name)
        return data_store[name]
    end

    function target:data_set(name, value)
        data_store[name] = value
    end

    return target
end

function test_transitive_indirect_includes(t)
    _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include/sub")
        os.mkdir("include/api")

        local h_main = path.join("include", "main.h")
        local h_bridge = path.join("include", "bridge.h")
        local h_middle = path.join("include", "sub", "middle.hpp")
        local h_leaf = path.join("include", "leaf_qobject.h")
        local h_fwd = path.join("src", "internal_fwd.h")
        local h_gadget = path.join("include", "api", "leaf_gadget.h")
        local h_unused = path.join("include", "unused_qobject.h")
        local f_main = path.join("src", "main.cpp")

        io.writefile(f_main, [[
#include "main.h"
#include "bridge.h"
#include "internal_fwd.h"
int main() { return 0; }
]])
        io.writefile(h_main, [[
class MainObj {
    Q_OBJECT
};
]])
        io.writefile(h_bridge, [[
#include "sub/middle.hpp"
class BridgePlain {};
]])
        io.writefile(h_middle, [[
#include "../leaf_qobject.h"
struct MiddlePlain {};
]])
        io.writefile(h_leaf, [[
class LeafObject {
    Q_OBJECT
};
]])
        -- internal_fwd.h is intentionally absent from target:headerfiles()
        io.writefile(h_fwd, [[
#include <api/leaf_gadget.h>
]])
        io.writefile(h_gadget, [[
struct LeafGadget {
    Q_GADGET
};
]])
        io.writefile(h_unused, [[
class UnusedObj {
    Q_OBJECT
};
]])

        local target = _mock_target({
            headerfiles = {h_main, h_bridge, h_middle, h_leaf, h_gadget, h_unused},
            sourcefiles = {f_main},
            includedirs = {"include"}
        })

        local detected = utils.detect_moc_headers(target)
        t:are_equal(detected, {h_main, h_leaf, h_gadget})
        -- subsequent call on the same target is skipped cleanly via qt.moc.headers_scanned
        t:are_equal(utils.detect_moc_headers(target), {})
    end)
end

function test_cycle_diamond_and_comments(t)
    _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include")

        local f_main = path.join("src", "main.cpp")
        local h_a = path.join("include", "cycle_a.h")
        local h_b = path.join("include", "cycle_b.h")
        local h_leaf = path.join("include", "cycle_leaf.h")
        local h_commented = path.join("include", "commented.h")
        local h_block_commented = path.join("include", "block_commented.h")
        local h_fake_qobject = path.join("include", "QObject.h")
        local h_commented_macro = path.join("include", "commented_macro.h")

        io.writefile(f_main, [[
#include <QObject>
#include "cycle_a.h"
#include "cycle_b.h"
// #include "commented.h"
/*
#include "block_commented.h"
*/
#include "commented_macro.h"
]])
        io.writefile(h_a, [[
#pragma once
#include "cycle_b.h"
]])
        io.writefile(h_b, [[
#pragma once
#include "cycle_a.h"
#  include   "cycle_leaf.h"
]])
        io.writefile(h_leaf, [[
class CycleLeaf {
    Q_OBJECT
};
]])
        io.writefile(h_commented, "class Commented { Q_OBJECT };\n")
        io.writefile(h_block_commented, "class BlockCommented { Q_OBJECT };\n")
        io.writefile(h_fake_qobject, "class FakeQObject { Q_OBJECT };\n")
        io.writefile(h_commented_macro, [[
class CommentedMacro {
    // Q_OBJECT
    /* Q_GADGET */
};
]])

        local target = _mock_target({
            headerfiles = {h_a, h_b, h_leaf, h_commented, h_block_commented, h_fake_qobject, h_commented_macro},
            sourcefiles = {f_main},
            includedirs = {"include"}
        })

        t:are_equal(utils.detect_moc_headers(target), {h_leaf})
    end)
end

function test_basename_collision_shadowing_and_explicit_header(t)
    _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include/mod_a")
        os.mkdir("include/mod_b")

        local f_main = path.join("src", "main.cpp")
        local h_mod_a = path.join("include", "mod_a", "widget.h")
        local h_mod_b = path.join("include", "mod_b", "widget.h")
        local h_local_shadow = path.join("src", "local.h")
        local h_include_shadowed = path.join("include", "local.h")
        local h_explicit = path.join("include", "explicit.h")
        local h_explicit_dep = path.join("include", "explicit_dep.h")

        io.writefile(f_main, [[
#include "mod_a/widget.h"
#include "local.h"
]])
        io.writefile(h_mod_a, "class WidgetA { Q_OBJECT };\n")
        io.writefile(h_mod_b, "class WidgetB { Q_OBJECT };\n")
        io.writefile(h_local_shadow, "class LocalPlain {};\n")
        io.writefile(h_include_shadowed, "class ShadowedObj { Q_OBJECT };\n")
        io.writefile(h_explicit, [[
#include "explicit_dep.h"
class ExplicitObj { Q_OBJECT };
]])
        io.writefile(h_explicit_dep, "class ExplicitDepObj { Q_OBJECT };\n")

        local target = _mock_target({
            headerfiles = {h_mod_a, h_mod_b, h_include_shadowed, h_explicit, h_explicit_dep},
            -- explicit.h uses a leading "./" to verify path normalization prevents duplicate detection
            sourcefiles = {f_main, path.join(".", h_explicit)},
            includedirs = {"include"}
        })

        t:are_equal(utils.detect_moc_headers(target), {h_mod_a, h_explicit_dep})
    end)
end

function test_moc_cpp_fallback_and_macro_cache_isolation(t)
    _with_temp_project(function ()
        os.mkdir("src")
        os.mkdir("include/sub")
        os.mkdir("include/other")
        os.mkdir("extra/ext")
        os.mkdir("ignored")

        local f_main = path.join("src", "main.cpp")
        local h_sub_panel = path.join("include", "sub", "panel.h")
        local h_other_panel = path.join("include", "other", "panel.h")
        local h_root_helper = path.join("include", "root_helper.h")
        local h_ext_raw = path.join("extra", "ext", "raw_view.h")
        local h_unrelated_raw = path.join("ignored", "raw_view.h")
        local h_custom = path.join("include", "custom_meta.h")

        io.writefile(f_main, [[
#include "sub/moc_panel.cpp"
#include "moc_root_helper.cpp"
#include "ext/raw_view.h"
#include "custom_meta.h"
]])
        io.writefile(h_sub_panel, "class SubPanel { Q_OBJECT };\n")
        io.writefile(h_other_panel, "class OtherPanel { Q_OBJECT };\n")
        io.writefile(h_root_helper, "class RootHelper { Q_OBJECT };\n")
        io.writefile(h_ext_raw, "class ExtRawView { Q_OBJECT };\n")
        io.writefile(h_unrelated_raw, "class IgnoredRawView { Q_OBJECT };\n")
        io.writefile(h_custom, "class CustomMeta { MY_META };\n")

        local requested_source = nil
        local t1 = _mock_target({
            headerfiles = {h_sub_panel, h_other_panel, h_root_helper, h_ext_raw, h_unrelated_raw, h_custom},
            sourcefiles = {f_main},
            includedirs = {"include"},
            on_get_from = function (_, source)
                requested_source = source
            end
        })
        t:are_equal(utils.detect_moc_headers(t1), {h_sub_panel, h_root_helper, h_ext_raw})
        t:are_equal(requested_source, "*")

        local t2 = _mock_target({
            headerfiles = {h_custom},
            sourcefiles = {f_main},
            includedirs = {"include"},
            macros = {"MY_META"}
        })
        t:are_equal(utils.detect_moc_headers(t2), {h_custom})
    end)
end

function test_external_and_package_headers_excluded(t)
    local extdir = os.tmpfile()
    os.mkdir(extdir)
    try
    {
        function ()
            local h_ext = path.join(extdir, "ext_bridge.h")
            io.writefile(h_ext, '#include "secret_leaf.h"\n')

            _with_temp_project(function ()
                os.mkdir("src")
                os.mkdir("include")
                os.mkdir("dep_inc")
                os.mkdir("pkg_inc")
                os.mkdir("dep_pkg_inc")

                local f_main = path.join("src", "main.cpp")
                local h_secret = path.join("include", "secret_leaf.h")
                local h_dep_bridge = path.join("dep_inc", "dep_bridge.h")
                local h_dep_leaf = path.join("include", "dep_leaf.h")
                local h_pkg_bridge = path.join("pkg_inc", "pkg_bridge.h")
                local h_pkg_leaf = path.join("include", "pkg_leaf.h")
                local h_dep_pkg_bridge = path.join("dep_pkg_inc", "dep_pkg_bridge.h")
                local h_dep_pkg_leaf = path.join("include", "dep_pkg_leaf.h")

                io.writefile(f_main, [[
#include "ext_bridge.h"
#include "dep_bridge.h"
#include "pkg_bridge.h"
#include "dep_pkg_bridge.h"
]])
                io.writefile(h_secret, "class SecretLeaf { Q_OBJECT };\n")
                io.writefile(h_dep_bridge, '#include "dep_leaf.h"\n')
                io.writefile(h_dep_leaf, "class DepLeaf { Q_OBJECT };\n")
                io.writefile(h_pkg_bridge, '#include "pkg_leaf.h"\n')
                io.writefile(h_pkg_leaf, "class PkgLeaf { Q_OBJECT };\n")
                io.writefile(h_dep_pkg_bridge, '#include "dep_pkg_leaf.h"\n')
                io.writefile(h_dep_pkg_leaf, "class DepPkgLeaf { Q_OBJECT };\n")

                local target = _mock_target({
                    headerfiles = {h_secret, h_dep_leaf, h_pkg_leaf, h_dep_pkg_leaf},
                    sourcefiles = {f_main},
                    includedirs_sources = {
                        {source = "self", dirs = {"include", extdir}},
                        {source = "dep::core", dirs = {"dep_inc"}},
                        {source = "package::qt5core", dirs = {"pkg_inc"}},
                        {source = "dep::core/package::qt5widgets", dirs = {"dep_pkg_inc"}}
                    }
                })

                -- dep::core is traversed, whereas external dirs, package::*, and dep::*/package::* are ignored
                t:are_equal(utils.detect_moc_headers(target), {h_dep_leaf})
            end)
        end,
        finally
        {
            function (ok, errors)
                os.tryrm(extdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

function test_need_moc_and_dynamic_generated_header(t)
    _with_temp_project(function ()
        os.mkdir("include")
        local h_gen = path.join("include", "generated.h")
        local h_slot = path.join("include", "pimpl_widget.h")
        local target = _mock_target({macros = {"CUSTOM_META"}})

        io.writefile(h_slot, [[
class PimplWidget {
    Q_OBJECT
    Q_PRIVATE_SLOT(d_func(), void _q_onChanged())
};
]])
        t:require(utils.has_q_private_slot(h_slot))
        t:require(utils.need_moc(target, h_slot))
        -- relative path alias "./..." hits the same normalized cache entry
        t:require(utils.has_qt_moc_macros(path.join(".", h_slot)))

        -- missing generated header must not negative-cache not_found across build stages
        t:require(utils.need_moc(target, h_gen))
        io.writefile(h_gen, "class PlainGenerated {};\n")
        t:require(not utils.need_moc(target, h_gen))
    end)
end
