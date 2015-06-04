--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        platform.lua
--

-- define module: platform
local platform = platform or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local global    = require("base/global")
local linker    = require("linker/linker")
local compiler  = require("compiler/compiler")

-- load prober the given platform directory
function platform._load_prober(root)

    -- the platform file path
    local file = string.format("%s/_prober.lua", root)
    if os.isfile(file) then

        -- load script
        local script = loadfile(file)
        if script then

            -- load prober
            local prober = script()
            if prober then

                -- ok
                return prober
            end
        end
    end
end

-- load the given platform from the given root directory
function platform._load_from(root, plat)

    -- the platform file path
    local file = string.format("%s/platform/%s/_%s.lua", root, plat, plat)
    if os.isfile(file) then

        -- load script
        local script = loadfile(file)
        if script then

            -- load module
            local module = script()
            if module then

                -- save directory
                module._DIRECTORY = path.directory(file)
                assert(module._DIRECTORY)

                -- attempt to load prober
                module._PROBER = platform._load_prober(module._DIRECTORY)

                -- ok
                return module
            end
        end
    end
end

-- load the given platform 
function platform._load(plat)

    -- the module
    platform._MODULES = platform._MODULES or {}
    local module = platform._MODULES[plat]

    -- return it directory if ok
    if module then return module end

    -- attempt to load it from the project configure directory 
    if not module then module = platform._load_from(config.directory(), plat) end

    -- attempt to load it from the global configure directory 
    if not module then module = platform._load_from(global.directory(), plat) end

    -- attempt to load it from the script directory 
    if not module then module = platform._load_from(xmake._SCRIPTS_DIR, plat) end

    -- cache it if ok
    if module then
        platform._MODULES[plat] = module
    end

    -- ok?
    return module
end

-- get the configure of the given platform
function platform._configs(plat)

    -- the configure
    platform._CONFIGS = platform._CONFIGS or {}
    local configs = platform._CONFIGS[plat]

    -- return it directly if exists
    if configs then
        return configs
    end

    -- load platform
    local module = platform._load(plat)
    if module then
          
        -- init configure
        platform._CONFIGS[plat]= {}
        configs = platform._CONFIGS[plat]

        -- make configure
        module.make(configs)
    end

    -- ok?
    return configs
end

-- make the current platform configure
function platform.make()

    -- make and get the current platform configure
    return platform._configs(config.get("plat"))
end

-- get the given configure
function platform.get(name)

    -- check
    assert(platform._CONFIGS)

    -- get the current platform configure
    local configs = platform._configs(config.get("plat"))
    if configs then
        -- get it
        return configs[name]
    end
end

-- get the linker from the given name
function platform.linker(kind)

    -- check
    assert(kind)
 
    -- init linkers
    platform._LINKERS = platform._LINKERS or {}
    local linkers = platform._LINKERS

    -- return it directly if the linker has been cached
    local l = linkers[kind]
    if l then return l end

    -- get linker
    local c = platform.get("linker")
    assert(c)

    -- load linker
    c = c[kind]
    if c then return linker.load(c) end

    -- cache this linker
    linkers[kind] = l

    -- ok
    return l
end

-- get the compiler from the given source file
function platform.compiler(srcfile)

    -- get the source file type
    local filetype = compiler.filetype(srcfile)
    if not filetype then
        return 
    end

    -- init compilers
    platform._COMPILERS = platform._COMPILERS or {}
    local compilers = platform._COMPILERS

    -- return it directly if the compiler has been cached
    local c = compilers[filetype]
    if c then return c, filetype end

    -- get compiler from the current platform
    c = platform.get("compiler")
    assert(c)

    -- load compiler
    c = c[filetype]
    if c then c = compiler.load(c) end

    -- cache this compiler
    compilers[filetype] = c

    -- ok
    return c, filetype
end

-- dump the platform configure
function platform.dump()
    
    -- check
    assert(platform._CONFIGS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(platform._configs(config.get("plat")))
    end
   
end

-- list all platforms
function platform.plats()
    
    -- return it directly if exists
    if platform._PLATS then
        return platform._PLATS 
    end

    -- make list
    local list = {}

    -- get the platform list from the project configure directory
    local plats = os.match(config.directory() .. "/platform/*", true)
    if plats then
        for _, v in ipairs(plats) do
            table.insert(list, path.basename(v))
        end
    end

    -- get the platform list from the global configure directory
    plats = os.match(global.directory() .. "/platform/*", true)
    if plats then
        for _, v in ipairs(plats) do
            table.insert(list, path.basename(v))
        end
    end
    
    -- get the platform list from the script directory
    plats = os.match(xmake._SCRIPTS_DIR .. "/platform/*", true)
    if plats then
        for _, v in ipairs(plats) do
            table.insert(list, path.basename(v))
        end
    end

    -- save it
    platform._PLATS = list

    -- ok
    return list
end

-- list all architectures
function platform.archs(plat)

    -- check
    assert(plat)
 
    -- load all platform configs
    local archs = {}
    local module = platform._load(plat)
    if module and module._ARCHS then
       for _, arch in ipairs(module._ARCHS) do
            table.insert(archs, arch)
       end
    end

    -- ok
    return archs
end

-- get the option menu for action: xmake config or global
function platform.menu(action)
    
    -- check
    assert(action)

    -- get all platforms
    local plats = platform.plats()
    assert(plats)

    -- load and merge all platform menus
    local menus = {}
    local exist = {}
    for _, plat in ipairs(plats) do

        -- load platform
        local module = platform._load(plat)
        if module and module.menu then

            -- get the platform menu
            local menu = module.menu(action)
            if menu then

                -- exists options?
                local exists = false
                for _, option in ipairs(menu) do
                    local name = option[2]
                    if name and not exist[name] then
                        exists = true
                        break
                    end
                end

                -- merge it and remove repeat if exists options
                if exists then
                    -- get the platform menu option
                    for _, option in ipairs(menu) do

                        -- merge it and remove repeat 
                        local name = option[2]
                        if name then
                            if not exist[name] then
                                table.insert(menus, option)
                                exist[name] = true
                            end
                        else
                            table.insert(menus, option)
                        end
                    end
                end
            end
        end
    end

    -- get all platform menus
    return menus
end

-- probe the platform configure 
function platform.probe(configs, is_global)

    -- probe global
    if is_global then

        -- get all platforms
        local plats = platform.plats()
        assert(plats)

        -- probe all platforms with the current host
        for _, plat in ipairs(plats) do
            local module = platform._load(plat)
            if module and module._PROBER and module._PROBER.done and module._HOST and module._HOST == xmake._HOST then
                module._PROBER.done(configs, is_global)
            end
        end

    -- probe config
    else
        -- probe it
        local module = platform._load(config.get("plat"))
        if module and module._PROBER and module._PROBER.done then
            module._PROBER.done(configs, is_global)
        end
    end
end
    
-- build target from the given makefile
function platform.build(mkfile, target)

    -- attempt to done the platform special make first
    local module = platform._load(config.get("plat"))
    if module and module._MAKER and module._MAKER.done then
        return module._MAKER.done(mkfile, target)
    end

    -- is verbose?
    local verbose = utils.ifelse(xmake._OPTIONS.verbose, "-v", "")

    -- make command
    local cmd = nil
    if mkfile and os.isfile(mkfile) then
        cmd = string.format("make -j4 -f %s %s VERBOSE=%s", mkfile, target or "", verbose)
    else  
        cmd = string.format("make -j4 %s VERBOSE=%s", target or "", verbose)
    end

    -- done 
    local ok = os.execute(cmd)
    if ok ~= 0 then
        return false
    end

    -- ok
    return true
end

-- return module: platform
return platform
