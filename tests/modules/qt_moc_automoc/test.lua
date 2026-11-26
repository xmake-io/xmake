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

function _write_files(files)
    for filepath, content in pairs(files) do
        os.mkdir(path.directory(filepath))
        io.writefile(filepath, content)
    end
end

function test_transitive_indirect_includes(t)
    _with_temp_project(function ()
        _write_files({
            ["src/main.cpp"] = '#include "main.h"\n#include "bridge.h"\n#include "internal_fwd.h"\n',
            ["include/main.h"] = "class MainObj { Q_OBJECT };",
            ["include/bridge.h"] = '#include "sub/middle.hpp"',
            ["include/sub/middle.hpp"] = '#include "../leaf_qobject.h"',
            ["include/leaf_qobject.h"] = "class LeafObject { Q_OBJECT };",
            ["src/internal_fwd.h"] = "#include <api/leaf_gadget.h>",
            ["include/api/leaf_gadget.h"] = "struct LeafGadget { Q_GADGET };",
            ["include/unused_qobject.h"] = "class UnusedObj { Q_OBJECT };"
        })
        local target = _mock_target({
            headerfiles = {"include/main.h", "include/bridge.h", "include/sub/middle.hpp",
                           "include/leaf_qobject.h", "include/api/leaf_gadget.h", "include/unused_qobject.h"},
            sourcefiles = {"src/main.cpp"},
            includedirs = {"include"}
        })
        t:are_equal(utils.detect_moc_headers(target), {"include/main.h", "include/leaf_qobject.h", "include/api/leaf_gadget.h"})
        t:are_equal(utils.detect_moc_headers(target), {})
    end)
end

function test_cycle_diamond_and_comments(t)
    _with_temp_project(function ()
        _write_files({
            ["src/main.cpp"] = [[
#include <QObject>
#include "cycle_a.h"
#include "cycle_b.h"
// #include "commented.h"
/* #include "block_commented.h" */
#include "commented_macro.h"
]],
            ["include/cycle_a.h"] = '#include "cycle_b.h"',
            ["include/cycle_b.h"] = '#include "cycle_a.h"\n#  include "cycle_leaf.h"',
            ["include/cycle_leaf.h"] = "class CycleLeaf { Q_OBJECT };",
            ["include/commented.h"] = "class Commented { Q_OBJECT };",
            ["include/block_commented.h"] = "class BlockCommented { Q_OBJECT };",
            ["include/QObject.h"] = "class FakeQObject { Q_OBJECT };",
            ["include/commented_macro.h"] = "class CommentedMacro {\n// Q_OBJECT\n/* Q_GADGET */\n};"
        })
        local target = _mock_target({
            headerfiles = {"include/cycle_a.h", "include/cycle_b.h", "include/cycle_leaf.h",
                           "include/commented.h", "include/block_commented.h", "include/QObject.h", "include/commented_macro.h"},
            sourcefiles = {"src/main.cpp"},
            includedirs = {"include"}
        })
        t:are_equal(utils.detect_moc_headers(target), {"include/cycle_leaf.h"})
    end)
end

function test_basename_collision_shadowing_and_explicit_header(t)
    _with_temp_project(function ()
        _write_files({
            ["src/main.cpp"] = '#include "mod_a/widget.h"\n#include "local.h"',
            ["include/mod_a/widget.h"] = "class WidgetA { Q_OBJECT };",
            ["include/mod_b/widget.h"] = "class WidgetB { Q_OBJECT };",
            ["src/local.h"] = "class LocalPlain {};",
            ["include/local.h"] = "class ShadowedObj { Q_OBJECT };",
            ["include/explicit.h"] = '#include "explicit_dep.h"\nclass ExplicitObj { Q_OBJECT };',
            ["include/explicit_dep.h"] = "class ExplicitDepObj { Q_OBJECT };"
        })
        local target = _mock_target({
            headerfiles = {"include/mod_a/widget.h", "include/mod_b/widget.h", "include/local.h",
                           "include/explicit.h", "include/explicit_dep.h"},
            sourcefiles = {"src/main.cpp", "./include/explicit.h"},
            includedirs = {"include"}
        })
        t:are_equal(utils.detect_moc_headers(target), {"include/mod_a/widget.h", "include/explicit_dep.h"})
    end)
end

function test_moc_cpp_fallback_and_macro_cache_isolation(t)
    _with_temp_project(function ()
        _write_files({
            ["src/main.cpp"] = '#include "sub/moc_panel.cpp"\n#include "moc_root_helper.cpp"\n#include "ext/raw_view.h"\n#include "custom_meta.h"',
            ["include/sub/panel.h"] = "class SubPanel { Q_OBJECT };",
            ["include/other/panel.h"] = "class OtherPanel { Q_OBJECT };",
            ["include/root_helper.h"] = "class RootHelper { Q_OBJECT };",
            ["extra/ext/raw_view.h"] = "class ExtRawView { Q_OBJECT };",
            ["ignored/raw_view.h"] = "class IgnoredRawView { Q_OBJECT };",
            ["include/custom_meta.h"] = "class CustomMeta { MY_META };"
        })
        local target = _mock_target({
            headerfiles = {"include/sub/panel.h", "include/other/panel.h", "include/root_helper.h",
                           "extra/ext/raw_view.h", "ignored/raw_view.h", "include/custom_meta.h"},
            sourcefiles = {"src/main.cpp"},
            includedirs = {"include"}
        })
        t:are_equal(utils.detect_moc_headers(target), {"include/sub/panel.h", "include/root_helper.h", "extra/ext/raw_view.h"})
        local custom = _mock_target({
            headerfiles = {"include/custom_meta.h"}, sourcefiles = {"src/main.cpp"},
            includedirs = {"include"}, macros = {"MY_META"}
        })
        t:are_equal(utils.detect_moc_headers(custom), {"include/custom_meta.h"})
    end)
end

function test_external_and_package_headers_excluded(t)
    _with_temp_project(function (extdir)
        io.writefile("ext_bridge.h", '#include "secret_leaf.h"')
        _with_temp_project(function ()
            _write_files({
                ["src/main.cpp"] = '#include "ext_bridge.h"\n#include "dep_bridge.h"\n#include "pkg_bridge.h"\n#include "dep_pkg_bridge.h"',
                ["include/secret_leaf.h"] = "class SecretLeaf { Q_OBJECT };",
                ["dep_inc/dep_bridge.h"] = '#include "dep_leaf.h"',
                ["include/dep_leaf.h"] = "class DepLeaf { Q_OBJECT };",
                ["pkg_inc/pkg_bridge.h"] = '#include "pkg_leaf.h"',
                ["include/pkg_leaf.h"] = "class PkgLeaf { Q_OBJECT };",
                ["dep_pkg_inc/dep_pkg_bridge.h"] = '#include "dep_pkg_leaf.h"',
                ["include/dep_pkg_leaf.h"] = "class DepPkgLeaf { Q_OBJECT };"
            })
            local target = _mock_target({
                headerfiles = {"include/secret_leaf.h", "include/dep_leaf.h", "include/pkg_leaf.h", "include/dep_pkg_leaf.h"},
                sourcefiles = {"src/main.cpp"},
                includedirs_sources = {
                    {source = "self", dirs = {"include", extdir}},
                    {source = "dep::core", dirs = {"dep_inc"}},
                    {source = "package::qt5core", dirs = {"pkg_inc"}},
                    {source = "dep::core/package::qt5widgets", dirs = {"dep_pkg_inc"}}
                }
            })
            t:are_equal(utils.detect_moc_headers(target), {"include/dep_leaf.h"})
        end)
    end)
end

function test_need_moc_and_dynamic_generated_header(t)
    _with_temp_project(function ()
        _write_files({["include/pimpl_widget.h"] = "class PimplWidget { Q_OBJECT Q_PRIVATE_SLOT(d_func(), void _q_onChanged()) };"})
        local target = _mock_target({macros = {"CUSTOM_META"}})
        t:require(utils.has_q_private_slot("include/pimpl_widget.h"))
        t:require(utils.need_moc(target, "include/pimpl_widget.h"))
        t:require(utils.has_qt_moc_macros("./include/pimpl_widget.h"))
        t:require(utils.need_moc(target, "include/generated.h"))
        io.writefile("include/generated.h", "class PlainGenerated {};")
        t:require(not utils.need_moc(target, "include/generated.h"))
    end)
end
