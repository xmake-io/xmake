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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("macosx")

    -- set os
    set_os("macosx")

    -- set hosts
    set_hosts("macosx")

    -- set archs
    set_archs("i386", "x86_64", "arm64")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).dylib")
    set_formats("symbol", "$(name).dSYM")

    -- set install directory
    set_installdir("/usr/local")

    -- on check
    on_check(function (platform)
        import("core.project.config")
        local arch = config.get("arch")
        if not arch then
            config.set("arch", os.arch())
            cprint("checking for architecture ... ${color.success}%s", config.get("arch"))
        end
    end)

    -- set toolchains
    set_toolchains("envs", "xcode", "clang", "gcc", "yasm", "nasm", "cuda", "dlang", "rust", "go", "gfortran", "zig")

    -- set menu
    set_menu {
                config =
                {
                    {category = "XCode SDK Configuration"                                                    }
                ,   {nil, "xcode",                   "kv", "auto",       "The Xcode Application Directory"   }
                ,   {nil, "xcode_sdkver",            "kv", "auto",       "The SDK Version for Xcode"         }
                ,   {nil, "xcode_bundle_identifier", "kv", "auto",       "The Bundle Identifier for Xcode"   }
                ,   {nil, "xcode_codesign_identity", "kv", "auto",       "The Codesign Identity for Xcode"   }
                ,   {nil, "xcode_mobile_provision",  "kv", "auto",       "The Mobile Provision for Xcode"    }
                ,   {nil, "target_minver",           "kv", "auto",       "The Target Minimal Version"        }
                ,   {category = "Cuda SDK Configuration"                                                     }
                ,   {nil, "cuda",                    "kv", "auto",       "The Cuda SDK Directory"            }
                ,   {category = "Qt SDK Configuration"                                                       }
                ,   {nil, "qt",                      "kv", "auto",       "The Qt SDK Directory"              }
                ,   {nil, "qt_sdkver",               "kv", "auto",       "The Qt SDK Version"                }
                ,   {category = "Vcpkg Configuration"                                                        }
                ,   {nil, "vcpkg",                   "kv", "auto",       "The Vcpkg Directory"               }
                }

            ,   global =
                {
                    {category = "XCode SDK Configuration"                                                    }
                ,   {nil, "xcode",                   "kv", "auto",       "The Xcode Application Directory"   }
                ,   {nil, "xcode_bundle_identifier", "kv", "auto",       "The Bundle Identifier for Xcode"   }
                ,   {nil, "xcode_codesign_identity", "kv", "auto",       "The Codesign Identity for Xcode"   }
                ,   {nil, "xcode_mobile_provision",  "kv", "auto",       "The Mobile Provision for Xcode"    }
                ,   {category = "Cuda SDK Configuration"                                                     }
                ,   {nil, "cuda",                    "kv", "auto",       "The Cuda SDK Directory"            }
                ,   {category = "Qt SDK Configuration"                                                       }
                ,   {nil, "qt",                      "kv", "auto",       "The Qt SDK Directory"              }
                ,   {category = "Vcpkg Configuration"                                                        }
                ,   {nil, "vcpkg",                   "kv", "auto",       "The Vcpkg Directory"               }
                }
            }






