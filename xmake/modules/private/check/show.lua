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
-- @author      Shiffted
-- @file        show.lua
--

function wshow(str, opt)
    opt = opt or {}
    _g.showed = _g.showed or {}
    local showed = _g.showed
    local infostr
    if str and opt.sourcetips then
        infostr = string.format("%s${clear}: %s", opt.sourcetips, str)
    elseif opt.sourcetips and opt.apiname and opt.value ~= nil then
        infostr = string.format("%s${clear}: unknown %s value '%s'", opt.sourcetips, opt.apiname, opt.value)
    elseif str then
        infostr = string.format("${clear}: %s", str)
    end
    if opt.probable_value then
        infostr = string.format("%s, it may be '%s'", infostr, opt.probable_value)
    end
    if not showed[infostr] then
        wprint(infostr)
        showed[infostr] = true
    end
end
