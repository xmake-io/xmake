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
-- Copyright (C) 2026, Xmake Open Source Community.
--
-- @author      karurochari
-- @file        check_alignof.lua
--

-- check c alignof(type) add to macro definition support cross compile
--
-- from https://github.com/xmake-io/xmake/issues/4345
--
-- e.g.
--
-- check_alignof("ALIGNOF_LONG", "long") => ALIGNOF_LONG=4
--
-- configvar_check_alignof("ALIGNOF_LONG", "long") => #define ALIGNOF_LONG 4
--
local binary_match_pattern = 'INFO:align%[(%d+)%]'

local check_alignof_template = [[
#define ALIGN (alignof(${TYPE}))
static char info_align[] =  {'I', 'N', 'F', 'O', ':', 'a','l','i','g','n','[',
  ('0' + ((ALIGN / 10000)%10)),
  ('0' + ((ALIGN / 1000)%10)),
  ('0' + ((ALIGN / 100)%10)),
  ('0' + ((ALIGN / 10)%10)),
  ('0' +  (ALIGN    % 10)),
  ']',
  '\0'};

int main(int argc, char *argv[]) {
  int require = 0;
  require += info_align[argc];
  (void)argv;
  return require;
}]]

function _binary_match(content)
    local match = content:match(binary_match_pattern)
    if match then
        return match:ltrim("0")
    end
end

function check_alignof(definition, typename, opt)
    opt = opt or {}
    if opt.number == nil then
        opt.number = true
    end
    local optname = opt.name or ("__" .. definition)
    local snippet = opt.snippet or ""
    interp_save_scope()
    option(optname)
        set_showmenu(false)
        add_cxxsnippets(definition, check_alignof_template:gsub('${TYPE}', typename), {binary_match = _binary_match})
        if opt.links then
            add_links(opt.links)
        end
        if opt.includes then
            add_cxxincludes(opt.includes)
        end
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cflags then
            add_cflags(opt.cflags)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.defines then
            add_defines(opt.defines)
        end
        if opt.warnings then
            set_warnings(opt.warnings)
        end
        after_check(function (option)
            if option:value() then
                if opt.number then
                    option:add("defines", definition .. "=" .. tonumber(option:value()))
                elseif opt.quote == false then
                    option:add("defines", definition .. "=" .. option:value())
                else
                    option:add("defines", definition .. "=\"" .. option:value() .. "\"")
                end
            end
        end)
    option_end()
    interp_restore_scope()
    add_options(optname)
end


function configvar_check_alignof(definition, typename, opt)
    opt = opt or {}
    if opt.number == nil then
        opt.number = true
    end
    local optname = opt.name or ("__" .. definition)
    local defname, defval = table.unpack(definition:split('='))
    interp_save_scope()
    option(optname)
        set_showmenu(false)
        add_cxxsnippets(definition, check_alignof_template:gsub('${TYPE}', typename), {binary_match = _binary_match})
        if opt.default == nil then
            set_configvar(defname, defval or 1, {quote = opt.quote})
        end
        if opt.links then
            add_links(opt.links)
        end
        if opt.includes then
            add_cxxincludes(opt.includes)
        end
        if opt.languages then
            set_languages(opt.languages)
        end
        if opt.cflags then
            add_cflags(opt.cflags)
        end
        if opt.cxflags then
            add_cxflags(opt.cxflags)
        end
        if opt.defines then
            add_defines(opt.defines)
        end
        if opt.warnings then
            set_warnings(opt.warnings)
        end
        after_check(function (option)
            if option:value() then
                option:set("configvar", defname, opt.number and tonumber(option:value()) or option:value(), {quote = opt.quote})
            end
        end)
    option_end()
    interp_restore_scope()
    if opt.default == nil then
        add_options(optname)
    else
        set_configvar(defname, has_config(optname) and (defval or 1) or opt.default, {quote = true})
    end
end

