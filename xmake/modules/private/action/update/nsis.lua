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
-- @author      Zhaoqi Xu
-- @file        nsis.lua
--

-- NSIS /D sets $INSTDIR. It must be the last argument and must not contain
-- quotes, even if the path contains spaces.
--
-- xmake/scripts/run.vbs quotes any argv that contains a space before
-- ShellExecute. Passing "/D=C:\Program Files\xmake" as one token would
-- become quoted and NSIS would reject it. Split on whitespace so VBS
-- concatenates an unquoted command line.
function installdir_params(installdir)
    return ("/D=" .. installdir):split("%s", {strict = true})
end
