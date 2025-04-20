--!A cross-toolchain build utility based on Lua
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
-- @file        toolchain.lua
--

-- define module
local toolchain      = toolchain or {}
local _instance     = _instance or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local option         = require("base/option")
local hashset        = require("base/hashset")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local config         = require("project/config")
local memcache       = require("cache/memcache")
local localcache     = require("cache/localcache")
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info, cachekey, is_builtin, configs)
    local instance       = table.inherit(_instance)
    local parts = name:split("::", {plain = true})
    instance._NAME = parts[#parts]
    table.remove(parts)
    if #parts > 0 then
        instance._NAMESPACE = table.concat(parts, "::")
    end
    instance._INFO       = info
    instance._IS_BUILTIN = is_builtin
    instance._CACHE      = toolchain._localcache()
    instance._CACHEKEY   = cachekey
    instance._CONFIGS    = instance._CACHE:get(cachekey) or {}
    for k, v in pairs(configs) do
        instance._CONFIGS[k] = v
    end
    -- is global toolchain for the whole platform?
    configs.plat = nil
    configs.arch = nil
    configs.cachekey = nil
    local plat = config.get("plat") or os.host()
    local arch = config.get("arch") or os.arch()
    if instance:is_plat(plat) and instance:is_arch(arch) and #table.keys(configs) == 0 then
        instance._CONFIGS.__global = true
    end
    return instance
end

-- get toolchain name
function _instance:name()
    return self._NAME
end

-- get the namespace
function _instance:namespace()
    return self._NAMESPACE
end

-- get the full name
function _instance:fullname()
    local namespace = self:namespace()
    return namespace and namespace .. "::" .. self:name() or self:name()
end

-- get toolchain platform
function _instance:plat()
    return self._PLAT or self:config("plat")
end

-- set toolchain platform
function _instance:plat_set(plat)
    self._PLAT = plat
end

-- get toolchain architecture
function _instance:arch()
    return self._ARCH or self:config("arch")
end

-- set toolchain architecture
function _instance:arch_set(arch)
    self._ARCH = arch
end

-- the current platform is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current architecture is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.join(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get toolchain info
function _instance:info()
    local arch = self:arch()
    local infos = self._INFOS
    if not infos then
        infos = {}
        self._INFOS = infos
    end
    local info = infos[arch]
    if not info then
        -- we need multiple info objects for different architectures
        info = self._INFO:clone()
        infos[arch] = info
    end
    return info
end

-- set the value to the toolchain configuration
function _instance:set(name, ...)
    self:info():apival_set(name, ...)
end

-- add the value to the toolchain configuration
function _instance:add(name, ...)
    self:info():apival_add(name, ...)
end

-- get the toolchain configuration
function _instance:get(name, opt)
    opt = opt or {}

    -- attempt to get the static configure value
    local value = self:info():get(name)
    if value ~= nil then
        return value
    end

    -- lazy loading toolchain
    if opt.load ~= false then
        self:_load()
        return self:info():get(name)
    end
end

-- get toolchain kind
function _instance:kind()
    return self:info():get("kind")
end

-- get toolchain formats, we must set it in description scope
-- @see https://github.com/xmake-io/xmake/issues/4769
function _instance:formats()
    return self:info():get("formats")
end

-- is cross-compilation toolchain?
function _instance:is_cross()
    if self:kind() == "cross" then
        return true
    elseif self:kind() == "standalone" and (self:cross() or self:config("sdkdir") or self:info():get("sdkdir")) then
        return true
    end
end

-- is standalone toolchain?
function _instance:is_standalone()
    return self:kind() == "standalone" or self:kind() == "cross"
end

-- is global toolchain for whole platform
function _instance:is_global()
    return self:config("__global")
end

-- is builtin toolchain? it's not from local project
function _instance:is_builtin()
    return self._IS_BUILTIN
end

-- get the run environments
function _instance:runenvs()
    local runenvs = self._RUNENVS
    if runenvs == nil then
        local toolchain_runenvs = self:get("runenvs")
        if toolchain_runenvs then
            runenvs = {}
            for name, values in pairs(toolchain_runenvs) do
                if type(values) == "table" then
                    values = path.joinenv(values)
                end
                runenvs[name] = values
            end
        end
        runenvs = runenvs or false
        self._RUNENVS = runenvs
    end
    return runenvs or nil
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    if not self:_is_checked() then
        utils.warning("we cannot get tool(%s) in toolchain(%s) with %s/%s, because it has been not checked yet!", toolkind, self:name(), self:plat(), self:arch())
    end
    -- ensure to do load for initializing toolset first
    -- @note we cannot call self:check() here, because it can only be called on config
    self:_load()
    local toolpaths = self:get("toolset." .. toolkind)
    if toolpaths then
        for _, toolpath in ipairs(table.wrap(toolpaths)) do
            local program, toolname = self:_checktool(toolkind, toolpath)
            if program then
                return program, toolname
            end
        end
    end
end

-- get the toolchain script
function _instance:script(name)
    return self:info():get(name)
end

-- get the cross
function _instance:cross()
    return self:config("cross") or config.get("cross") or self:info():get("cross")
end

-- get the bin directory
function _instance:bindir()
    local bindir = self:config("bindir") or config.get("bin") or self:info():get("bindir")
    if not bindir and self:sdkdir() and os.isdir(path.join(self:sdkdir(), "bin")) then
        bindir = path.join(self:sdkdir(), "bin")
    end
    return bindir
end

-- get the sdk directory
function _instance:sdkdir()
    return self:config("sdkdir") or config.get("sdk") or self:info():get("sdkdir")
end

-- get cachekey
function _instance:cachekey()
    return self._CACHEKEY
end

-- get user config from `set_toolchains("", {configs = {vs = "2018"}})`
function _instance:config(name)
    return self._CONFIGS[name]
end

-- set user config
function _instance:config_set(name, data)
    self._CONFIGS[name] = data
end

-- save user configs
function _instance:configs_save()
    self._CACHE:set(self:cachekey(), self._CONFIGS)
    self._CACHE:save()
end

-- do check, we only check it once for all architectures
function _instance:check(opt)

    opt = opt or {}
    local checked_config = "__checked"
    if opt.ignore_sdk then
        checked_config = checked_config .. "_sdk_ignored"
    end
    local checked = self:config(checked_config)
    if checked == nil then
        local on_check = self:_on_check()
        if on_check then
            local ok, results_or_errors = sandbox.load(on_check, self, opt)
            if ok then
                checked = results_or_errors
            else
                os.raise(results_or_errors)
            end
        else
            checked = true
        end
        -- we need to persist this state
        checked = checked or false
        self:config_set(checked_config, checked)
        self:configs_save()
    end
    return checked
end

-- do load manually, it will call on_load()
function _instance:load()
    self:_load()
end

-- check cross toolchain
function _instance:check_cross_toolchain()
    return sandbox_module.import("toolchains.cross.check", {rootdir = os.programdir(), anonymous = true})(self)
end

-- load cross toolchain
function _instance:load_cross_toolchain()
    return sandbox_module.import("toolchains.cross.load", {rootdir = os.programdir(), anonymous = true})(self)
end

-- get packages
function _instance:packages()
    local packages = self._PACKAGES
    if packages == nil then
        local project = require("project/project")
        -- we will get packages from `set_toolchains("foo", {packages})` or `set_toolchains("foo@packages")`
        for _, pkgname in ipairs(table.wrap(self:config("packages"))) do
            local requires = project.required_packages()
            if requires then
                local pkginfo = requires[pkgname]
                if pkginfo then
                    packages = packages or {}
                    table.insert(packages, pkginfo)
                end
            end
        end
        self._PACKAGES = packages or false
    end
    return packages or nil
end

-- save toolchain to file
function _instance:savefile(filepath)
    if not self:_is_loaded() then
        os.raise("we can only save toolchain(%s) after it has been loaded!", self:name())
    end
    -- we strip on_load/on_check scripts to solve some issues
    -- @see https://github.com/xmake-io/xmake/issues/3774
    local info = table.clone(self:info():info())
    info.load = nil
    info.check = nil
    return io.save(filepath, {name = self:name(), info = info, cachekey = self:cachekey(), configs = self._CONFIGS})
end

-- on check (builtin)
function _instance:_on_check()
    local on_check = self:info():get("check")
    if not on_check and self:is_cross() then
        on_check = self.check_cross_toolchain
    end
    return on_check
end

-- on load (builtin)
function _instance:_on_load()
    local on_load = self:info():get("load")
    if not on_load and self:is_cross() then
        on_load = self.load_cross_toolchain
    end
    return on_load
end

-- do load, @note we need to load it repeatly for each architectures
function _instance:_load()
    if not self:_is_checked() then
        utils.warning("we cannot load toolchain(%s), because it has been not checked yet!", self:name(), self:plat(), self:arch())
    end
    local info = self:info()
    if not info:get("__loaded") and not info:get("__loading") then
        local on_load = self:_on_load()
        if on_load then
            info:set("__loading", true)
            local ok, errors = sandbox.load(on_load, self)
            info:set("__loading", false)
            if not ok then
                os.raise(errors)
            end
        end
        info:set("__loaded", true)
    end
end

-- is loaded?
function _instance:_is_loaded()
    return self:info():get("__loaded")
end

-- is checked?
function _instance:_is_checked()
    return self:config("__checked") ~= nil or self:_on_check() == nil
end

-- get the tool description from the tool kind
function _instance:_description(toolkind)
    local descriptions = self._DESCRIPTIONS
    if not descriptions then
        descriptions =
        {
            cc         = "the c compiler",
            cxx        = "the c++ compiler",
            cpp        = "the c/c++ preprocessor",
            ld         = "the linker",
            sh         = "the shared library linker",
            ar         = "the static library archiver",
            mrc        = "the windows resource compiler",
            strip      = "the symbols stripper",
            ranlib     = "the archive index generator",
            objcopy    = "the GNU objcopy utility",
            dsymutil   = "the symbols generator",
            mm         = "the objc compiler",
            mxx        = "the objc++ compiler",
            as         = "the assember",
            sc         = "the swift compiler",
            scld       = "the swift linker",
            scsh       = "the swift shared library linker",
            gc         = "the golang compiler",
            gcld       = "the golang linker",
            gcar       = "the golang static library archiver",
            dc         = "the dlang compiler",
            dcld       = "the dlang linker",
            dcsh       = "the dlang shared library linker",
            dcar       = "the dlang static library archiver",
            rc         = "the rust compiler",
            rcld       = "the rust linker",
            rcsh       = "the rust shared library linker",
            rcar       = "the rust static library archiver",
            fc         = "the fortran compiler",
            fcld       = "the fortran linker",
            fcsh       = "the fortran shared library linker",
            zc         = "the zig compiler",
            zcld       = "the zig linker",
            zcsh       = "the zig shared library linker",
            zcar       = "the zig static library archiver",
            cu         = "the cuda compiler",
            culd       = "the cuda linker",
            cuccbin    = "the cuda host c++ compiler",
            nc         = "the nim compiler",
            ncld       = "the nim linker",
            ncsh       = "the nim shared library linker",
            ncar       = "the nim static library archiver",
            kc         = "the kotlin native compiler",
            kcld       = "the kotlin native linker",
            kcsh       = "the kotlin native shared library linker",
            kcar       = "the kotlin native static library archiver",
        }
        self._DESCRIPTIONS = descriptions
    end
    return descriptions[toolkind]
end

-- check the given tool path
function _instance:_checktool(toolkind, toolpath)

    -- get result from cache first
    local cachekey = self:cachekey() .. "_checktool" .. toolkind
    local result = toolchain._memcache():get3(cachekey, toolkind, toolpath)
    if result then
        return result[1], result[2]
    end

    -- get find_tool
    local find_tool = self._find_tool
    if not find_tool then
        find_tool = sandbox_module.import("lib.detect.find_tool", {anonymous = true})
        self._find_tool = find_tool
    end

    -- do filter for toolpath variables, e.g. set_toolset("cc", "$(env CC)")
    local sandbox_inst = sandbox.instance()
    if sandbox_inst then
        local filter = sandbox_inst:filter()
        if filter then
            local value = filter:handle(toolpath)
            if value and value:trim() ~= "" then
                toolpath = value
            else
                return
            end
        end
    end

    -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
    -- https://github.com/xmake-io/xmake/issues/1361
    local program, toolname
    if toolpath then
        local pos = toolpath:find('@', 1, true)
        if pos then
            -- we need to ignore valid path with `@`, e.g. /usr/local/opt/go@1.17/bin/go
            -- https://github.com/xmake-io/xmake/issues/2853
            local prefix = toolpath:sub(1, pos - 1)
            if prefix and not prefix:find("[/\\]") then
                toolname = prefix
                program = toolpath:sub(pos + 1)
            end
        end
    end

    -- find tool program
    local tool = find_tool(toolpath, {toolchain = self,
        cachekey = cachekey,
        program = program or toolpath,
        paths = self:bindir(),
        envs = self:get("runenvs")})
    if tool then
        program = tool.program
        toolname = toolname or tool.name
    end

    -- get tool description from the tool kind
    local description = self:_description(toolkind) or ("unknown toolkind " .. toolkind)

    -- trace
    if option.get("verbose") then
        if program then
            utils.cprint("${dim}checking for %s (%s) ... ${color.success}%s", description, toolkind, path.filename(program))
        else
            utils.cprint("${dim}checking for %s (%s: ${bright}%s${clear}) ... ${color.nothing}${text.nothing}", description, toolkind, toolpath)
        end
    end
    toolchain._memcache():set3(cachekey, toolkind, toolpath, {program, toolname})
    return program, toolname
end

-- get memcache
function toolchain._memcache()
    return memcache.cache("core.tool.toolchain")
end

-- get local cache
function toolchain._localcache()
    return localcache.cache("toolchain")
end

-- the interpreter
function toolchain._interpreter()

    -- the interpreter has been initialized? return it directly
    if toolchain._INTERPRETER then
        return toolchain._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define(toolchain.apis())

    -- define apis for language
    interp:api_define(language.apis())

    -- save interpreter
    toolchain._INTERPRETER = interp
    return interp
end

-- get cache key
function toolchain._cachekey(name, opt)
    local cachekey = opt.cachekey
    if not cachekey then
        cachekey = name
        for _, k in ipairs(table.orderkeys(opt)) do
            local v = opt[k]
            cachekey = cachekey .. "_" .. k .. "_" .. tostring(v)
        end
    end
    return cachekey
end

-- parse toolchain and package name
--
-- format: toolchain@package
-- e.g. "clang@llvm-10", "@muslcc", zig
--
function toolchain.parsename(name)
    local splitinfo = name:split('@', {plain = true, strict = true})
    local toolchain_name = splitinfo[1]
    if toolchain_name == "" then
        toolchain_name = nil
    end
    local packages = splitinfo[2]
    if packages == "" then
        packages = nil
    end
    return toolchain_name or packages, packages
end

-- get toolchain apis
function toolchain.apis()
    return
    {
        values =
        {
            "toolchain.set_kind"
        ,   "toolchain.set_cross"
        ,   "toolchain.set_bindir"
        ,   "toolchain.set_sdkdir"
        ,   "toolchain.set_archs"
        ,   "toolchain.set_runtimes"
        ,   "toolchain.set_homepage"
        ,   "toolchain.set_description"
        }
    ,   keyvalues =
        {
            -- toolchain.set_xxx
            "toolchain.set_formats"
        ,   "toolchain.set_toolset"
        ,   "toolchain.add_toolset"
            -- toolchain.add_xxx
        ,   "toolchain.add_runenvs"
        }
    ,   script =
        {
            -- toolchain.on_xxx
            "toolchain.on_load"
        ,   "toolchain.on_check"
        }
    }
end

-- get toolchain directories
function toolchain.directories()
    local dirs = toolchain._DIRS or {   path.join(global.directory(), "toolchains")
                                    ,   path.join(os.programdir(), "toolchains")
                                    }
    toolchain._DIRS = dirs
    return dirs
end

-- add toolchain directories
function toolchain.add_directories(...)
    local dirs = toolchain.directories()
    for _, dir in ipairs({...}) do
        table.insert(dirs, 1, dir)
    end
    toolchain._DIRS = table.unique(dirs)
end

-- load toolchain
function toolchain.load(name, opt)

    -- get toolchain name and packages
    opt = opt or {}
    local packages
    name, packages = toolchain.parsename(name)
    opt.packages = opt.packages or packages

    -- get cache
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()
    local cache = toolchain._memcache()
    local cachekey = toolchain._cachekey(name, opt)

    -- get it directly from cache dirst
    local instance = cache:get(cachekey)
    if instance then
        return instance
    end

    -- find the toolchain script path
    local scriptpath = nil
    for _, dir in ipairs(toolchain.directories()) do
        scriptpath = path.join(dir, name, "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the toolchain %s not found!", name)
    end

    -- get interpreter
    local interp = toolchain._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load toolchain
    local results, errors = interp:make("toolchain", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the toolchain name
    local result = results[name]
    if not result then
        return nil, string.format("the toolchain %s not found!", name)
    end

    -- save instance to the cache
    instance = _instance.new(name, result, cachekey, true, opt)
    cache:set(cachekey, instance)
    return instance
end

-- load toolchain from the give toolchain info
function toolchain.load_withinfo(name, info, opt)

    -- get toolchain name and packages
    opt = opt or {}
    local packages
    name, packages = toolchain.parsename(name)
    opt.packages = opt.packages or packages

    -- get cache key
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()
    local cache = toolchain._memcache()
    local cachekey = toolchain._cachekey(name, opt)

    -- get it directly from cache dirst
    local instance = cache:get(cachekey)
    if instance then
        return instance
    end

    -- save instance to the cache
    instance = _instance.new(name, info, cachekey, false, opt)
    cache:set(cachekey, instance)
    return instance
end

-- load toolchain from file
function toolchain.load_fromfile(filepath, opt)
    local fileinfo, errors = io.load(filepath)
    if not fileinfo then
        return nil, errors
    end
    if not fileinfo.name or not fileinfo.info then
        return nil, string.format("%s is invalid toolchain info file!", filepath)
    end
    opt = table.join(opt or {}, fileinfo.configs)
    opt.cachekey = fileinfo.cachekey
    local scope_opt = {interpreter = toolchain._interpreter(), deduplicate = true, enable_filter = true}
    local info = scopeinfo.new("toolchain", fileinfo.info, scope_opt)
    local instance = toolchain.load_withinfo(fileinfo.name, info, opt)
    return instance
end


-- get the program and name of the given tool kind
function toolchain.tool(toolchains, toolkind, opt)

    -- get plat and arch
    opt = opt or {}
    local plat = opt.plat or config.get("plat") or os.host()
    local arch = opt.arch or config.get("arch") or os.arch()

    -- get cache and cachekey
    local cache = toolchain._localcache()
    local cachekey = "tool_" .. (opt.cachekey or "") .. "_" .. plat .. "_" .. arch .. "_" .. toolkind
    local updatecache = false

    -- get program from before_script
    local program, toolname, toolchain_info
    local before_get = opt.before_get
    if before_get then
        program, toolname, toolchain_info = before_get(toolkind)
        if program then
            updatecache = true
        end
    end

    -- get program from local cache
    if not program then
        program = cache:get2(cachekey, "program")
        toolname = cache:get2(cachekey, "toolname")
        toolchain_info = cache:get2(cachekey, "toolchain_info")
    end

    -- get program from toolchains
    if not program then
        for idx, toolchain_inst in ipairs(toolchains) do
            program, toolname = toolchain_inst:tool(toolkind)
            if program then
                toolchain_info = {name = toolchain_inst:name(),
                                  plat = toolchain_inst:plat(),
                                  arch = toolchain_inst:arch(),
                                  cachekey = toolchain_inst:cachekey()}
                updatecache = true
                break
            end
        end
    end

    -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
    if program and type(program) == "string" then
        local pos = program:find('@', 1, true)
        if pos then
            -- we need to ignore valid path with `@`, e.g. /usr/local/opt/go@1.17/bin/go
            -- https://github.com/xmake-io/xmake/issues/2853
            local prefix = program:sub(1, pos - 1)
            if prefix and not prefix:find("[/\\]") then
                toolname = prefix
                program = program:sub(pos + 1)
            end
            updatecache = true
        end
    end

    -- update cache
    if program and updatecache then
        cache:set2(cachekey, "program", program)
        cache:set2(cachekey, "toolname", toolname)
        cache:set2(cachekey, "toolchain_info", toolchain_info)
        cache:save()
    end
    return program, toolname, toolchain_info
end

-- get tool configuration from the toolchains
function toolchain.toolconfig(toolchains, name, opt)

    -- get plat and arch
    opt = opt or {}
    local plat = opt.plat or config.get("plat") or os.host()
    local arch = opt.arch or config.get("arch") or os.arch()

    -- get cache and cachekey
    local cache = toolchain._memcache()
    local cachekey = "toolconfig_" .. (opt.cachekey or "") .. "_" .. plat .. "_" .. arch

    -- get configuration
    local toolconfig = cache:get2(cachekey, name)
    if toolconfig == nil then
        for _, toolchain_inst in ipairs(toolchains) do
            if not toolchain_inst:_is_checked() then
                utils.warning("we cannot get toolconfig(%s) in toolchain(%s) with %s/%s, because it has been not checked yet!", name, toolchain_inst:name(), toolchain_inst:plat(), toolchain_inst:arch())
            end
            local values = toolchain_inst:get(name)
            if values then
                toolconfig = toolconfig or {}
                table.join2(toolconfig, values)
            end
            local after_get = opt.after_get
            if after_get then
                values = after_get(toolchain_inst, name)
                if values then
                    toolconfig = toolconfig or {}
                    table.join2(toolconfig, values)
                end
            end
        end
        cache:set2(cachekey, name, toolconfig or false)
    end
    return toolconfig or nil
end

-- return module
return toolchain
