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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        language.lua
--

-- define module
local language      = language or {}
local _instance     = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local interpreter   = require("base/interpreter")
local sandbox       = require("sandbox/sandbox")
local config        = require("project/config")
local global        = require("base/global")

-- new an instance
function _instance.new(name, info, rootdir)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._ROOTDIR = rootdir
    return instance
end

-- get the language configure
function _instance:get(name)
    local info = self._INFO:info()
    local value = info[name]
    if value ~= nil then
        return value
    end

    if self._g == nil and info.load ~= nil then
        local ok, results = sandbox.load(info.load)
        if not ok then
            os.raise(results)
        end
        self._g = results
    end
    return self._g[name]
end

-- get the language menu
function _instance:menu()
    return self._INFO:get("menu")
end

-- get the language name
function _instance:name()
    return self._NAME
end

-- get the source extensions
function _instance:extensions()
    if self._EXTENSIONS then
        return self._EXTENSIONS
    end

    -- get extensions
    local extensions = {}
    for sourcekind, exts in pairs(self:sourcekinds()) do
        for _, extension in ipairs(table.wrap(exts)) do
            extensions[extension:lower()] = sourcekind
        end
    end

    self._EXTENSIONS = extensions
    return extensions
end

-- get the rules
function _instance:rules()
    return self._INFO:get("rules")
end

-- get the source kinds
function _instance:sourcekinds()
    return self._INFO:get("sourcekinds")
end

-- get the source flags
function _instance:sourceflags()
    return self._INFO:get("sourceflags")
end

-- get the target kinds (targetkind => linkerkind)
--
-- e.g.
-- {binary = "ld", static = "ar", shared = "sh"}
--
function _instance:kinds()
    return self._INFO:get("targetkinds")
end

-- get the target flags (targetkind => linkerflag)
--
-- e.g.
-- {binary = "ldflags", static = "arflags", shared = "shflags"}
--
function _instance:targetflags()
    return self._INFO:get("targetflags")
end

-- get the mixing kinds for linker
--
-- e.g.
-- {"cc", "cxx"}
--
function _instance:mixingkinds()
    return self._INFO:get("mixingkinds")
end

-- get the language kinds
function _instance:langkinds()
    return self._INFO:get("langkinds")
end

-- get the name flags
function _instance:nameflags()

    -- attempt to get it from cache first
    if self._NAMEFLAGS then
        return self._NAMEFLAGS
    end

    -- get nameflags
    local results = {}
    for targetkind, nameflags in pairs(table.wrap(self._INFO:get("nameflags"))) do

        -- make tool info
        local toolinfo = results[targetkind] or {}
        for _, namedflag in ipairs(nameflags) do

            -- split it by '.'
            local splitinfo = namedflag:split('.', {plain = true})
            assert(#splitinfo == 2)

            -- get flag scope
            local flagscope = splitinfo[1]
            assert(flagscope)

            -- get flag info
            local flaginfo = splitinfo[2]:split(':')

            -- get flag name
            local flagname = flaginfo[1]
            assert(flagname)

            -- get check state
            local checkstate = false
            if #flaginfo == 2 and flaginfo[2] == "check" then
                checkstate = true
            end

            -- insert this flag info
            table.insert(toolinfo, {flagscope, flagname, checkstate})
        end

        -- save this tool info
        results[targetkind] = toolinfo
    end

    -- cache this results
    self._NAMEFLAGS = results
    return results
end

-- the directory of language
function language._directory()
    return path.join(os.programdir(), "languages")
end

-- the interpreter
function language._interpreter()

    -- the interpreter has been initialized? return it directly
    if language._INTERPRETER then
        return language._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define
    {
        values =
        {
            -- language.set_xxx
            "language.set_mixingkinds"
            -- language.add_xxx
        ,   "language.add_rules"
        }
    ,   script =
        {
            -- language.on_xxx
            "language.on_load"
        ,   "language.on_check_main"
        }
    ,   dictionary =
        {
            -- language.set_xxx
            "language.set_menu"
        ,   "language.set_nameflags"
        ,   "language.set_langkinds"
        ,   "language.set_sourcekinds"
        ,   "language.set_sourceflags"
        ,   "language.set_targetkinds"
        ,   "language.set_targetflags"
        }
    }
    language._INTERPRETER = interp
    return interp
end

-- load the language from the given name (c++, objc++, swift, golang, asm, ...)
function language.load(name)

    -- load all languages
    if not name then
        if not language._LANGUAGES then
            for _, name in ipairs(table.wrap(os.match(path.join(language._directory(), "*"), true))) do
                local instance, errors = language.load(path.basename(name))
                if not instance then
                    return nil, errors
                end
            end
        end
        return language._LANGUAGES
    end

    -- get it directly from cache dirst
    language._LANGUAGES = language._LANGUAGES or {}
    if language._LANGUAGES[name] then
        return language._LANGUAGES[name]
    end

    -- find the language script path
    local scriptpath = path.join(path.join(language._directory(), name), "xmake.lua")
    if not os.isfile(scriptpath) then
        return nil, string.format("the language %s not found!", name)
    end

    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the language %s not found!", name)
    end

    -- get interpreter
    local interp = language._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load language
    local results, errors = interp:make("language", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the language name
    if not results[name] then
        return nil, string.format("the language %s not found!", name)
    end

    -- new an instance
    local instance, errors = _instance.new(name, results[name], language._interpreter():rootdir())
    if not instance then
        return nil, errors
    end
    language._LANGUAGES[name] = instance
    return instance
end

-- load the language from the given source kind: cc, cxx, mm, mxx, sc, gc, as ..
function language.load_sk(sourcekind)

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        return nil, errors
    end

    -- make source kind as lower
    sourcekind = sourcekind:lower()

    -- get it directly from cache dirst
    language._LANGUAGES_OF_SK = language._LANGUAGES_OF_SK or {}
    if language._LANGUAGES_OF_SK[sourcekind] then
        return language._LANGUAGES_OF_SK[sourcekind]
    end

    -- find language instance
    local result = nil
    for _, instance in pairs(languages) do
        if instance:sourcekinds()[sourcekind] ~= nil then
            result = instance
            break
        end
    end
    if not result then
        return nil, string.format("unknown language sourcekind: %s", sourcekind)
    end
    language._LANGUAGES_OF_SK[sourcekind] = result
    return result
end

-- load the language from the given source extension: .c, .cpp, .m, .mm, .swift, .go, .s ..
function language.load_ex(extension)

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        return nil, errors
    end

    -- make source extension as lower
    extension = extension:lower()

    -- get it directly from cache dirst
    language._LANGUAGES_OF_EX = language._LANGUAGES_OF_EX or {}
    if language._LANGUAGES_OF_EX[extension] then
        return language._LANGUAGES_OF_EX[extension]
    end

    -- find language instance
    local result = nil
    for _, instance in pairs(languages) do
        if instance:extensions()[extension] ~= nil then
            result = instance
            break
        end
    end
    if not result then
        return nil, string.format("unknown language source extension: %s", extension)
    end
    language._LANGUAGES_OF_EX[extension] = result
    return result
end


-- load the language apis
function language.apis()
    local apis = language._APIS
    if not apis then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        apis = {values = {}, paths = {}, custom = {}, dictionary = {}}
        for name, instance in pairs(languages) do
            local instance_apis = instance:get("apis")
            if instance_apis then
                table.join2(apis.values,     table.wrap(instance_apis.values))
                table.join2(apis.paths,      table.wrap(instance_apis.paths))
                table.join2(apis.custom,     table.wrap(instance_apis.custom))
                table.join2(apis.dictionary, table.wrap(instance_apis.dictionary))
            end
        end
        apis.values = table.unique(apis.values)
        apis.paths  = table.unique(apis.paths)
        apis.custom = table.unique(apis.custom)
        language._APIS = apis
    end
    return apis
end

-- get language source extensions
--
-- e.g.
--
-- {
--      [".c"]      = cc
-- ,    [".cc"]     = cxx
-- ,    [".cpp"]    = cxx
-- ,    [".m"]      = mm
-- ,    [".mm"]     = mxx
-- ,    [".swift"]  = sc
-- ,    [".go"]     = gc
-- }
--
function language.extensions()
    local extensions = language._EXTENSIONS
    if not extensions then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        extensions = {}
        for name, instance in pairs(languages) do
            table.join2(extensions, instance:extensions())
        end
        language._EXTENSIONS = extensions
    end
    return extensions
end

-- get language source kinds
--
-- e.g.
--
-- {
--      cc  = ".c"
-- ,    cxx = {".cc", ".cpp", ".cxx"}
-- ,    mm  = ".m"
-- ,    mxx = ".mm"
-- ,    sc  = ".swift"
-- ,    gc  = ".go"
-- }
--
function language.sourcekinds()
    local sourcekinds = language._SOURCEKINDS
    if not sourcekinds then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        sourcekinds = {}
        for name, instance in pairs(languages) do
            table.join2(sourcekinds, instance:sourcekinds())
        end
        language._SOURCEKINDS = sourcekinds
    end
    return sourcekinds
end

-- get language source flags
--
-- e.g.
--
-- {
--      cc  = {"cflags", "cxflags"}
-- ,    cxx = {"cxxflags", "cxflags"}
-- ,    ...
-- }
--
function language.sourceflags()
    local sourceflags = language._SOURCEFLAGS
    if not sourceflags then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        sourceflags = {}
        for name, instance in pairs(languages) do
            table.join2(sourceflags, instance:sourceflags())
        end
        language._SOURCEFLAGS = sourceflags
    end
    return sourceflags
end

-- get source kind of the source file name
function language.sourcekind_of(sourcefile)

    -- get the source file extension
    local extension = path.extension(sourcefile)
    if not extension then
        return nil, string.format("%s has not extension", sourcefile)
    end

    -- get extensions
    local extensions = language.extensions()

    -- get source kind from extension
    local sourcekind = extensions[extension:lower()]
    if not sourcekind then
        return nil, string.format("%s is unknown extension", extension)
    end
    return sourcekind
end

-- get extension of the source kind
function language.extension_of(sourcekind)
    local extension = table.wrap(language.sourcekinds()[sourcekind])[1]
    if not extension then
        return nil, string.format("%s is unknown source kind", sourcekind)
    end
    return extension
end

-- get linker infos(kind and flag) of the target kind and the source kinds
function language.linkerinfos_of(targetkind, sourcekinds)

    -- load linkerinfos
    local linkerinfos = language._LINKERINFOS
    if not linkerinfos then

        -- load all languages
        local languages, errors = language.load()
        if not languages then
            return nil, errors
        end

        -- make linker infos
        linkerinfos = {}
        for name, instance in pairs(languages) do
            for _, mixingkind in ipairs(table.wrap(instance:mixingkinds())) do
                local targetflags = instance:targetflags()
                for _targetkind, linkerkind in pairs(table.wrap(instance:kinds())) do

                    -- init linker info
                    linkerinfos[_targetkind] = linkerinfos[_targetkind] or {}
                    linkerinfos[_targetkind][linkerkind] = linkerinfos[_targetkind][linkerkind] or {}
                    local linkerinfo = linkerinfos[_targetkind][linkerkind]

                    -- sve linker info
                    local linkerflag = targetflags[_targetkind]
                    linkerinfo.linkerkind = linkerkind
                    if linkerflag then
                        linkerinfo.linkerflag = linkerflag
                    end
                    linkerinfo.mixingkinds = linkerinfo.mixingkinds or {}
                    linkerinfo.mixingkinds[mixingkind] = 1
                    linkerinfo.sourcecount = (linkerinfo.sourcecount or 0) + 1
                end
            end
        end
        language._LINKERINFOS = linkerinfos
    end

    -- find suitable linkers
    local results = {}
    for _, linkerinfo in pairs(table.wrap(linkerinfos[targetkind])) do

        -- match all source kinds?
        local count = 0
        for _, sourcekind in ipairs(sourcekinds) do
            count = count + (linkerinfo.mixingkinds[sourcekind] or 0)
        end
        if count == #sourcekinds then
            table.insert(results, linkerinfo)
        end
    end
    if #results > 0 then
        -- sort it by most matches
        table.sort(results, function(a, b) return a.sourcecount > b.sourcecount end)
        return results
    end

    -- not suitable linker
    return nil, string.format("no suitable linker for %s.{%s}", targetkind, table.concat(sourcekinds, ' '))
end

-- get language target kinds
--
-- e.g.
--
-- {
--      binary = {"ld", "gcld", "dcld"}
-- ,    static = {"ar", "gcar", "dcar"}
-- ,    shared = {"sh", "dcsh"}
-- }
--
function language.targetkinds()
    local targetkinds = language._TARGETKINDS
    if not targetkinds then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        targetkinds = {}
        for name, instance in pairs(languages) do
            for targetkind, linkerkind in pairs(table.wrap(instance:kinds())) do
                targetkinds[targetkind] = targetkinds[targetkind] or {}
                table.insert(targetkinds[targetkind], linkerkind)
            end
        end
        for targetkind, linkerkinds in pairs(targetkinds) do
            targetkinds[targetkind] = table.unique(linkerkinds)
        end
        language._TARGETKINDS = targetkinds
    end
    return targetkinds
end

-- get language kinds (langkind => sourcekind)
--
-- e.g.
--
-- {
--      c           = "cc"
-- ,    cxx         = "cxx"
-- ,    m           = "mm"
-- ,    mxx         = "mxx"
-- ,    swift       = "sc"
-- ,    go          = "gc"
-- ,    as          = "as"
-- ,    rust        = "rc"
-- ,    d           = "dc"
-- }
--
function language.langkinds()
    local langkinds = language._LANGKINDS
    if not langkinds then
        local languages, errors = language.load()
        if not languages then
            os.raise(errors)
        end
        langkinds = {}
        for name, instance in pairs(languages) do
            table.join2(langkinds, instance:langkinds())
        end
        language._LANGKINDS = langkinds
    end
    return langkinds
end

return language
