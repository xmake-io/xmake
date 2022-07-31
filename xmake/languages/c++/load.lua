--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- get function name and function info
--
-- sigsetjmp
-- sigsetjmp((void*)0, 0)
-- sigsetjmp{sigsetjmp((void*)0, 0);}
-- sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
function _funcinfo(func)
    local name, code = string.match(func, "(.+){(.+)}")
    if code == nil then
        local pos = func:find("%(")
        if pos then
            name = func:sub(1, pos - 1)
            code = func
        else
            name = func
            code = string.format("volatile void* p%s = (void*)&%s;", name, name)
        end
    end
    return name:trim(), code
end

-- TODO add c function, deprecated
function _api_add_cfunc(interp, module, alias, links, includes, func)

    -- parse the function info
    local funcname, funccode = _funcinfo(func)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = format("__%s_%s", module, funcname)
    else
        name = format("__%s", funcname)
    end

    -- uses the alias name
    if alias ~= nil then
        funcname = alias
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = format("$(prefix)_%s_HAVE_%s", module:upper(), funcname:upper())
    else
        define = format("$(prefix)_HAVE_%s", funcname:upper())
    end

    -- save the current scope
    interp:api_builtin_save_scope()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_category", "cfuncs")
    interp:api_call("add_cfuncs", func)
    if links then interp:api_call("add_links", links) end
    if includes then interp:api_call("add_cincludes", includes) end

    -- restore the current scope
    interp:api_builtin_restore_scope()

    -- add this option
    interp:api_call("add_options", name)
end

-- TODO add c functions, deprecated
function _api_add_cfuncs(interp, module, links, includes, ...)
    wprint("target.add_cfuncs is deprecated, please use option.add_cfuncs()")
    for _, func in ipairs({...}) do
        _api_add_cfunc(interp, module, nil, links, includes, func)
    end
end

-- TODO add c++ function, deprecated
function _api_add_cxxfunc(interp, module, alias, links, includes, func)

    -- parse the function info
    local funcname, funccode = _funcinfo(func)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = format("__%s_%s", module, funcname)
    else
        name = format("__%s", funcname)
    end

    -- uses the alias name
    if alias ~= nil then
        funcname = alias
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = format("$(prefix)_%s_HAVE_%s", module:upper(), funcname:upper())
    else
        define = format("$(prefix)_HAVE_%s", funcname:upper())
    end

    -- save the current scope
    interp:api_builtin_save_scope()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_category", "cxxfuncs")
    interp:api_call("add_cxxfuncs", func)
    if links then interp:api_call("add_links", links) end
    if includes then interp:api_call("add_cxxincludes", includes) end

    -- restore the current scope
    interp:api_builtin_restore_scope()

    -- add this option
    interp:api_call("add_options", name)
end

-- TODO add c++ functions, deprecated
function _api_add_cxxfuncs(interp, module, links, includes, ...)
    wprint("target.add_cxxfuncs is deprecated, please use option.add_cxxfuncs()")
    for _, func in ipairs({...}) do
        _api_add_cxxfunc(interp, module, nil, links, includes, func)
    end
end

-- get apis
function _get_apis()
    local apis = {}
    apis.values = {
        -- target.add_xxx
        "target.add_links"
    ,   "target.add_syslinks"
    ,   "target.add_cflags"
    ,   "target.add_cxflags"
    ,   "target.add_cxxflags"
    ,   "target.add_ldflags"
    ,   "target.add_arflags"
    ,   "target.add_shflags"
    ,   "target.add_defines"
    ,   "target.add_undefines"
    ,   "target.add_frameworks"
    ,   "target.add_rpathdirs"  -- @note do not translate path, it's usually an absolute path or contains $ORIGIN/@loader_path
        -- option.add_xxx
    ,   "option.add_cincludes"
    ,   "option.add_cxxincludes"
    ,   "option.add_cfuncs"
    ,   "option.add_cxxfuncs"
    ,   "option.add_ctypes"
    ,   "option.add_cxxtypes"
    ,   "option.add_links"
    ,   "option.add_syslinks"
    ,   "option.add_cflags"
    ,   "option.add_cxflags"
    ,   "option.add_cxxflags"
    ,   "option.add_ldflags"
    ,   "option.add_arflags"
    ,   "option.add_shflags"
    ,   "option.add_defines"
    ,   "option.add_undefines"
    ,   "option.add_frameworks"
    ,   "option.add_rpathdirs"
        -- package.add_xxx
    ,   "package.add_links"
    ,   "package.add_syslinks"
    ,   "package.add_cflags"
    ,   "package.add_cxflags"
    ,   "package.add_cxxflags"
    ,   "package.add_ldflags"
    ,   "package.add_arflags"
    ,   "package.add_shflags"
    ,   "package.add_defines"
    ,   "package.add_undefines"
    ,   "package.add_frameworks"
    ,   "package.add_rpathdirs"
    ,   "package.add_linkdirs"
    ,   "package.add_includedirs" --@note we need not uses paths for package, see https://github.com/xmake-io/xmake/issues/717
    ,   "package.add_sysincludedirs"
    ,   "package.add_frameworkdirs"
        -- toolchain.add_xxx
    ,   "toolchain.add_links"
    ,   "toolchain.add_syslinks"
    ,   "toolchain.add_cflags"
    ,   "toolchain.add_cxflags"
    ,   "toolchain.add_cxxflags"
    ,   "toolchain.add_ldflags"
    ,   "toolchain.add_arflags"
    ,   "toolchain.add_shflags"
    ,   "toolchain.add_defines"
    ,   "toolchain.add_undefines"
    ,   "toolchain.add_frameworks"
    ,   "toolchain.add_rpathdirs"
    ,   "toolchain.add_linkdirs"
    ,   "toolchain.add_includedirs"
    ,   "toolchain.add_sysincludedirs"
    ,   "toolchain.add_frameworkdirs"
    }
    apis.paths = {
        -- target.set_xxx
        "target.set_headerdir"        -- TODO deprecated
    ,   "target.set_config_header"    -- TODO deprecated
    ,   "target.set_pcheader"
    ,   "target.set_pcxxheader"
        -- target.add_xxx
    ,   "target.add_headers"          -- TODO deprecated
    ,   "target.add_headerfiles"
    ,   "target.add_linkdirs"
    ,   "target.add_includedirs"
    ,   "target.add_sysincludedirs"
    ,   "target.add_frameworkdirs"
        -- option.add_xxx
    ,   "option.add_linkdirs"
    ,   "option.add_includedirs"
    ,   "option.add_sysincludedirs"
    ,   "option.add_frameworkdirs"
    }
    apis.dictionary = {
        -- option.add_xxx
        "option.add_csnippets"
    ,   "option.add_cxxsnippets"
    }
    apis.custom = {
        -- target.add_xxx
        {"target.add_cfunc",        _api_add_cfunc      }
    ,   {"target.add_cfuncs",       _api_add_cfuncs     }
    ,   {"target.add_cxxfunc",      _api_add_cxxfunc    }
    ,   {"target.add_cxxfuncs",     _api_add_cxxfuncs   }
    }
    return apis
end

function main()
    return {apis = _get_apis()}
end


