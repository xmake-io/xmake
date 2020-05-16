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

-- define toolchain
toolchain("xcode")

    -- set toolsets
    set_toolsets("cc", "xcrun -sdk macosx clang")
    set_toolsets("cxx", "xcrun -sdk macosx clang", "xcrun -sdk macosx clang++")
    set_toolsets("as", "xcrun -sdk macosx clang")
    set_toolsets("ld", "xcrun -sdk macosx clang++", "xcrun -sdk macosx clang")
    set_toolsets("sh", "xcrun -sdk macosx clang++", "xcrun -sdk macosx clang")
    set_toolsets("ar", "xcrun -sdk macosx ar")
    set_toolsets("ex", "xcrun -sdk macosx ar")
    set_toolsets("strip", "xcrun -sdk macosx strip")
    set_toolsets("dsymutil", "xcrun -sdk macosx dsymutil", "dsymutil")
    set_toolsets("mm", "xcrun -sdk macosx clang")
    set_toolsets("mxx", "xcrun -sdk macosx clang", "xcrun -sdk macosx clang++")
    set_toolsets("sc", "xcrun -sdk macosx swiftc", "swiftc")
    set_toolsets("scld", "xcrun -sdk macosx swiftc", "swiftc")
    set_toolsets("scsh", "xcrun -sdk macosx swiftc", "swiftc")

