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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      JassJam
-- @file        xmake.lua
--

-- define rule: build csharp target with dotnet
--
-- @code
-- target("app")
--     set_kind("binary") -- or "shared"
--     add_rules("csharp")
--     add_files("src/*.cs", "src/app.csproj")
--
--     -- optional: override runtime identifier (arch-specific) for self-contained publish (e.g. "win-x64", "linux-x64", "osx-x64", "osx-arm64")
--     -- add_values("csharp.runtime_identifier", "win-x64")
-- @endcode
--
rule("csharp")
    set_extensions(".cs", ".csproj")
    set_sourcekinds("cs", "csproj", {objectfiles = false})
    on_load("load")
    on_buildcmd("buildcmd")
    on_clean("clean")
    on_install("install")
    on_installcmd("installcmd")
