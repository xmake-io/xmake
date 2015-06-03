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
local linker    = require("linker/linker")
local compiler  = require("compiler/compiler")

-- load the given platform 
function platform._load(plat)
 
    -- load it
    return require("platform/" .. plat .. "/_" .. plat)
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
    local p = platform._load(plat)
    if p then
          
        -- init configure
        platform._CONFIGS[plat]= {}
        configs = platform._CONFIGS[plat]

        -- make configure
        p.make(configs)
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

    -- get the platform list
    local plats = os.match(xmake._SCRIPTS_DIR .. "/platform/*", true)
    if plats then
        for i, v in ipairs(plats) do
            plats[i] = path.basename(v)
        end
    end

    -- save it
    platform._PLATS = plats

    -- ok
    return plats
end

-- list all architectures
function platform.archs(plat)

    -- check
    assert(plat)
 
    -- load all platform configs
    local archs = {}
    local p = platform._load(plat)
    if p and p._ARCHS then
       for _, arch in ipairs(p._ARCHS) do
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
        local p = platform._load(plat)
        if p and p.menu then

            -- get the platform menu
            local menu = p.menu(action)
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
            local p = platform._load(plat)
            if p and p._PROBER and p._PROBER.done and p._HOST and p._HOST == xmake._HOST then
                p._PROBER.done(configs, is_global)
            end
        end

    -- probe config
    else
        -- probe it
        local p = platform._load(config.get("plat"))
        if p and p._PROBER and p._PROBER.done then
            p._PROBER.done(configs, is_global)
        end
    end
end
    
-- build target from the given makefile
function platform.build(mkfile, target)

    -- attempt to done the platform special make first
    local p = platform._load(config.get("plat"))
    if p and p._MAKER and p._MAKER.done then
        return p._MAKER.done(mkfile, target)
    end

    -- make command
    local cmd = nil
    if mkfile and os.isfile(mkfile) then
        cmd = string.format("make -j4 -f %s %s", mkfile, target or "")
    else  
        cmd = string.format("make -j4 %s", target or "")
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
