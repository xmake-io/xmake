import("core.base.json")
import("core.project.config")
import("core.tool.compiler")
import("core.cache.globalcache")
import("lib.detect")

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
    --[[
    local compinst = compiler.load("cxx", {target = target})

    local toolname = compinst:_tool():name()
    local compinfos = detect.find_tool(toolname, {version=true, program=toolname})
    local compiler = compinfos.name
    local version = compinfos.version()

    local stlcachedir = globalcache.cache("stlbmi")
    --]]

    local stlcachedir = path.join(target:autogendir(), ".gens", "stlmodules", "cache")
    if not os.isdir(stlcachedir) then
        os.mkdir(stlcachedir)
    end

    return stlcachedir
end

function get_cache_dir(target)
    local cachedir = path.join(target:autogendir(), "rules", "modules", "cache")
    if not os.isdir(cachedir) then
        os.mkdir(cachedir)
    end

    return cachedir
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

function parseDependencyDatas(target, moduleinfos, opt)
    local cachedir = get_cache_dir(target)
    local modules
    for _, moduleinfo in ipairs(moduleinfos) do
        assert(moduleinfo.version <= 1)
        for _, rule in ipairs(moduleinfo.rules) do
            modules = modules or {}

            local m = {}

            for _, provide in ipairs(rule.provides) do
                m.provides = m.provides or {}

                if provide["compiled-module-path"] then
                    if not path.is_absolute(provide["compiled-module-path"]) then
                        m.provides[provide["logical-name"] ] = path.absolute(provide["compiled-module-path"])
                    else
                        m.provides[provide["logical-name"] ] = provide["compiled-module-path"]
                    end
                else -- assume path with name
                    local name = provide["logical-name"] .. ".ifc"
                    name:replace(":", "-")

                    m.provides[provide["logical-name"] ] = { 
                        bmi = path.join(cachedir, name), 
                        sourcefile = moduleinfo.sourcefile 
                    }
                end
            end

            modules[rule["primary-output"] ] = m
        end
    end

    for _, moduleinfo in ipairs(moduleinfos) do
        for _, rule in ipairs(moduleinfo.rules) do
            local m = modules[rule["primary-output"] ]
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
                    path = p,
                    unique = r["unique-on-source-path"] or false
                }
            end
        end
    end 

    return modules
end