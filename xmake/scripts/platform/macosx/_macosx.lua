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
-- @file        _macosx.lua
--

-- define module: _macosx
local _macosx = _macosx or {}

-- load modules
local config    = require("base/config")

-- init host
_macosx._HOST   = "macosx"

-- init architectures
_macosx._ARCHS  = {"x86", "x64"}

-- init prober
_macosx._PROBER = require("platform/macosx/_prober")

-- make configure
function _macosx.make(configs)

    -- init the file name format
    configs.format = {}
    configs.format.static = {"lib", ".a"}
    configs.format.object = {"",    ".o"}
    configs.format.shared = {"",    ".dylib"}

    -- init the compiler
    configs.compiler = {}
    configs.compiler.cc  = config.get("cc") or "xcrun -sdk macosx clang"
    configs.compiler.cxx = config.get("cxx") or "xcrun -sdk macosx clang++"
    configs.compiler.mm  = config.get("mm") or configs.compiler.cc
    configs.compiler.mxx = config.get("mxx") or configs.compiler.cxx

    -- init the linker
    configs.linker = {}
    configs.linker.ld = config.get("ld") or configs.compiler.cxx

    -- init the assembler
    configs.assembler = {}
    configs.assembler.as = config.get("as") or configs.compiler.cc

    -- init the cflags
    configs.compiler.cflags             = {}
    configs.compiler.cflags.opti        = {}
    configs.compiler.cflags.warn        = {}
    configs.compiler.cflags.all         = "-c"
    configs.compiler.cflags.debug       = "-g"
    configs.compiler.cflags.release     = "-fomit-frame-pointer -fvisibility=hidden"
    configs.compiler.cflags.profile     = ""
    configs.compiler.cflags.opti.O0     = "-O0"
    configs.compiler.cflags.opti.O1     = "-O1"
    configs.compiler.cflags.opti.O2     = "-O2"
    configs.compiler.cflags.opti.O3     = "-O3"
    configs.compiler.cflags.opti.Os     = "-Os"
    configs.compiler.cflags.warn.W0     = "-W0"
    configs.compiler.cflags.warn.W1     = "-W1"
    configs.compiler.cflags.warn.W2     = "-W2"
    configs.compiler.cflags.warn.W3     = "-W3"
    configs.compiler.cflags.warn.We     = "-Werror"

    -- init the cxxflags
    configs.compiler.cxxflags           = {}
    configs.compiler.cxxflags.opti      = configs.compiler.cflags.opti
    configs.compiler.cxxflags.warn      = configs.compiler.cflags.warn
    configs.compiler.cxxflags.all       = ""
    configs.compiler.cxxflags.debug     = "-g"
    configs.compiler.cxxflags.release   = "-fomit-frame-pointer -fvisibility=hidden"
    configs.compiler.cxxflags.profile   = ""

    -- init xcode sdk directory
    configs.xcode_sdkdir = config.get("xcode_dir") .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. config.get("xcode_sdkver") .. ".sdk"
end

-- get the option menu for action: xmake config or global
function _macosx.menu(action)

    -- init config option menu
    _macosx._MENU_CONFIG = _macosx._MENU_CONFIG or
            {   {}   
            ,   {nil, "mm",             "kv", nil,          "The Objc Compiler"                 }
            ,   {nil, "mxx",            "kv", nil,          "The Objc++ Compiler"               }
            ,   {nil, "mflags",         "kv", nil,          "The Objc Compiler Flags"           }
            ,   {nil, "mxflags",        "kv", nil,          "The Objc/c++ Compiler Flags"       }
            ,   {nil, "mxxflags",       "kv", nil,          "The Objc++ Compiler Flags"         }
            ,   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"   }
            ,   {nil, "xcode_sdkver",   "kv", "auto",       "The SDK Version for Xcode"         }
            ,   }

    -- init global option menu
    _macosx._MENU_GLOBAL = _macosx._MENU_GLOBAL or
            {   {}
            ,   {nil, "xcode_dir",      "kv", "auto",       "The Xcode Application Directory"   }
            ,   }

    -- get the option menu
    if action == "config" then
        return _macosx._MENU_CONFIG
    elseif action == "global" then
        return _macosx._MENU_GLOBAL
    end
end

-- return module: _macosx
return _macosx
