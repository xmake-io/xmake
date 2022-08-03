import("core.base.json")
import("core.project.config")
import("core.tool.compiler")
import("core.project.project")
import("lib.detect.find_file")

local stl_headers = {
    "algorithm",
    "forward_list",
    "numbers",
    "stop_token",
    "any",
    "fstream",
    "numeric",
    "streambuf",
    "array",
    "functional",
    "optional",
    "string",
    "atomic",
    "future",
    "ostream",
    "string_view",
    "barrier",
    "initializer_list",
    "queue",
    "bit",
    "iomanip",
    "random",
    "syncstream",
    "bitset",
    "ios",
    "ranges",
    "system_error",
    "charconv",
    "iosfwd",
    "ratio",
    "thread",
    "chrono",
    "iostream",
    "regex",
    "tuple",
    "codecvt",
    "istream",
    "scoped_allocator",
    "typeindex",
    "compare",
    "iterator",
    "semaphore",
    "typeinfo",
    "complex",
    "latch",
    "set",
    "type_traits",
    "concepts",
    "limits",
    "shared_mutex",
    "unordered_map",
    "condition_variable",
    "list",
    "source_location",
    "unordered_set",
    "coroutine",
    "locale",
    "span",
    "utility",
    "deque",
    "map",
    "spanstream",
    "valarray",
    "exception",
    "memory",
    "sstream",
    "variant",
    "execution",
    "memory_resource",
    "stack",
    "vector",
    "filesystem",
    "mutex",
    "version",
    "format",
    "new",
    "type_traits",
    "string_view",
    "stdexcept"}

function get_stl_headers()
    return stl_headers
end 

function is_stl_header(header)
    for _, stl_header in ipairs(stl_headers) do
        if stl_header == header then 
            return true
        end
    end

    return false
end

function get_stlcache_dir(target)
    local stlcachedir = path.join(target:autogendir(), "stlmodules", "cache")
    if target:has_tool("cxx", "clang", "clangxx") then
        stlcachedir = path.join(config.buildir(), "stlmodules", "cache")
    end
    if not os.isdir(stlcachedir) then
        os.mkdir(stlcachedir)
    end

    return path.translate(stlcachedir)
end

function get_cache_dir(target)
    local cachedir = path.join(target:autogendir(), "rules", "modules", "cache")
    if not os.isdir(cachedir) then
        os.mkdir(cachedir)
    end

    return path.translate(cachedir)
end

function patch_sourcebatch(target, sourcebatch, opt)
    local cachedir = get_cache_dir(target)

    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do 
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

end

function get_bmi_ext(target)
    if target:has_tool("cxx", "gcc", "gxx") then
        return import("gcc").get_bmi_ext()
    elseif target:has_tool("cxx", "cl") then
        return import("msvc").get_bmi_ext()
    elseif target:has_tool("cxx", "clang", "clangxx") then
        return import("clang").get_bmi_ext()
    end

    assert(false)
end

function modules_support(target)
    local module_builder
    if target:has_tool("cxx", "clang", "clangxx") then
        module_builder = import("clang", {anonymous = true})
    elseif target:has_tool("cxx", "gcc", "gxx") then
        module_builder = import("gcc", {anonymous = true})
    elseif target:has_tool("cxx", "cl") then
        module_builder = import("msvc", {anonymous = true})
    else
        local _, toolname = target:tool("cxx")
        raise("compiler(%s): does not support c++ module!", toolname)
    end
    return module_builder
end

function contains_modules(target)
    local target_with_modules
    for _, dep in ipairs(target:orderdeps()) do
        local sourcebatches = dep:sourcebatches()
        if sourcebatches and sourcebatches["c++.build.modules"] then
            target_with_modules = true
            break
        end
    end
    return target_with_modules
end

function load(target, sourcebatch, opt)
    local cachedir = get_cache_dir(target)

    local moduleinfos
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local dependfile = target:dependfile(sourcefile)
        if os.isfile(dependfile) then
            local data = io.load(dependfile)

            if data then
                moduleinfos = moduleinfos or {}

                local moduleinfo = json.decode(data.moduleinfo)
                moduleinfo.sourcefile = sourcefile
                if moduleinfo then
                    table.append(moduleinfos, moduleinfo)
                end
            end
        end
    end

    return moduleinfos
end

function parse_dependency_data(target, moduleinfos, opt)
    local cachedir = get_cache_dir(target)

    local modules
    for _, moduleinfo in ipairs(moduleinfos) do
        assert(moduleinfo.version <= 1)
        for _, rule in ipairs(moduleinfo.rules) do
            modules = modules or {}

            local m = {}

            for _, provide in ipairs(rule.provides) do
                m.provides = m.provides or {}

                assert(provide["logical-name"])
                if provide["compiled-module-path"] then
                    if not path.is_absolute(provide["compiled-module-path"]) then
                        m.provides[provide["logical-name"] ] = path.absolute(path.translate(provide["compiled-module-path"]))
                    else
                        m.provides[provide["logical-name"] ] = path.translate(provide["compiled-module-path"])
                    end
                else -- assume path with name
                    local name = provide["logical-name"] .. get_bmi_ext(target)
                    name:replace(":", "-")

                    m.provides[provide["logical-name"] ] = { 
                        bmi = path.join(cachedir, name), 
                        sourcefile = moduleinfo.sourcefile 
                    }
                end
            end

            assert(rule["primary-output"])
            modules[path.translate(rule["primary-output"])] = m
        end
    end

    for _, moduleinfo in ipairs(moduleinfos) do
        for _, rule in ipairs(moduleinfo.rules) do
            local m = modules[path.translate(rule["primary-output"])]
            for _, r in ipairs(rule.requires) do
                m.requires = m.requires or {}

                local p = r["source-path"]
                if not p then
                    for _, dependency in pairs(modules) do
                        if dependency.provides and dependency.provides[r["logical-name"] ] then
                            p = dependency.provides[r["logical-name"] ].bmi
                            break
                        end
                    end
                end

                m.requires[r["logical-name"] ] = {
                    method = r["lookup-method"] or "by-name",
                    path = p and path.translate(p) or nil,
                    unique = r["unique-on-source-path"] or false
                }
            end
        end
    end 

    return modules
end

function _topological_sort_visit(node, nodes, modules, output)
    if node.marked then
        return
    end

    assert(not node.tempmarked)

    node.tempmarked = true

    local m1 = modules[node.objectfile]

    assert(m1.provides)
    for _, n in ipairs(nodes) do
        if not n.tempmarked then
            local m2 = modules[n.objectfile]

            for name, provide in pairs(m1.provides) do
                if m2.requires and m2.requires[name] then
                    _topological_sort_visit(n, nodes, modules, output)
                end
            end
        end
    end

    node.tempmarked = false
    node.marked = true

    table.insert(output, 1, node.objectfile)
end

function _topological_sort_has_node_without_mark(nodes)
    for _, node in ipairs(nodes) do
        if not node.marked then
            return true
        end
    end

    return false
end

function _topological_sort_get_first_unmarked_node(nodes)
    for _, node in ipairs(nodes) do
        if not node.marked and not node.tempmarked then
            return node
        end
    end
end

function sort_modules_by_dependencies(objectfiles, modules)
    local output = {}

    local nodes  = {}
    for _, objectfile in ipairs(objectfiles) do 
        local m = modules[objectfile]

        if m.provides then
            table.append(nodes, { marked = false, tempmarked = false, objectfile = objectfile })
        end
    end

    while _topological_sort_has_node_without_mark(nodes) do
        local node = _topological_sort_get_first_unmarked_node(nodes)

        _topological_sort_visit(node, nodes, modules, output)
    end

    return output
end

function find_quote_header_file(target, sourcefile, file)
    local p = path.join(path.directory(path.absolute(sourcefile, project.directory())), file)

    assert(os.isfile(p))

    return p
end

function find_angle_header_file(target, file)
    -- check if the header is in subtarget
    
    local modules_support
    if target:has_tool("cxx", "clang", "clangxx") then
        modules_support = import("clang")
    elseif target:has_tool("cxx", "gcc", "gxx") then
        modules_support = import("gcc")
    elseif target:has_tool("cxx", "cl") then
        modules_support = import("msvc")
    else
        local _, toolname = target:tool("cxx")
        raise("compiler(%s): does not support c++ module!", toolname)
    end

    local headerpaths = modules_support.toolchain_include_directories(target)

    for _, dep in ipairs(target:orderdeps()) do
        table.append(headerpaths, dep:scriptdir())
    end

    if project.required_packages then
        for _, name in ipairs(target:get("packages")) do
            local package = project.required_package(name)
            table.join2(headerpaths, package:get("sysincludedirs"))
        end
    end

    table.join2(headerpaths, target:get("includedirs"))

    local p = find_file(file, headerpaths)

    assert(p)
    assert(os.isfile(p))

    return p
end

function fallback_generate_dependencies(target, jsonfile, sourcefile)
    local output = {
        version = 0,
        revision = 0,
        rules = {}
    }

    local rule = {
        outputs = {
            jsonfile
        }
    }
    rule["primary-output"] = target:objectfile(sourcefile)

    local module_name
    local module_deps = {}
    local sourcecode = io.readfile(sourcefile)
    sourcecode = sourcecode:gsub("//.-\n", "\n")
    sourcecode = sourcecode:gsub("/%*.-%*/", "")
    for _, line in ipairs(sourcecode:split("\n", {plain = true})) do
        if not module_name then
            module_name = line:match("export%s+module%s+(.+)%s*;")
        end

        local module_depname = line:match("import%s+(.+)%s*;")

        if module_depname then
            local module_dep = {}

            -- partition? import :xxx;
            if module_depname:startswith(":") then
                module_depname = module_name .. module_depname
            elseif module_depname:startswith("\"") then
                module_depname = module_depname:sub(2, -2)
                module_dep["lookup-method"] = "include-quote"
                module_dep["unique-on-source-path"] = true
                module_dep["source-path"] = find_quote_header_file(target, sourcefile, module_depname)
            elseif module_depname:startswith("<") then
                module_depname = module_depname:sub(2, -2)
                module_dep["lookup-method"] = "include-angle"
                module_dep["unique-on-source-path"] = true
                module_dep["source-path"] = find_angle_header_file(target, module_depname)
            end

            module_dep["logical-name"] = module_depname

            table.insert(module_deps, module_dep)
        end
    end

    if module_name then
        table.append(rule.outputs, module_name .. get_bmi_ext(target))
      
        local provide = {}
        provide["logical-name"] = module_name
        provide["source-path"] = path.absolute(sourcefile, project.directory())

        rule.provides = {}
        table.append(rule.provides, provide)
    end

    rule.requires = module_deps

    table.append(output.rules, rule)

    local jsondata = json.encode(output)

    io.writefile(jsonfile, jsondata)
end