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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        template.lua
--

-- define module: template
local template = template or {}

-- load modules
local os                = require("base/os")
local io                = require("base/io")
local path              = require("base/path")
local table             = require("base/table")
local utils             = require("base/utils")
local string            = require("base/string")
local option            = require("base/option")
local sandbox           = require("sandbox/sandbox")
local project           = require("project/project")
local interpreter       = require("base/interpreter")
local deprecated        = require("base/deprecated")

-- the interpreter
function template._interpreter()

    -- the interpreter has been initialized? return it directly
    if template._INTERPRETER then
        return template._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis (only root scope)
    interp:api_define
    {
        values =
        {
            -- set_xxx
            "set_name"
        ,   "set_description"
        ,   "set_projectdir"
            -- add_xxx
        ,   "add_macrofiles"
        }
    ,   script =
        {
            -- on_xxx
            "on_create"
        }
    ,   dictionary = 
        {
            -- set_xxx
            "set_macros"
            -- add_xxx
        ,   "add_macros"
        }
    }

    -- save interpreter
    template._INTERPRETER = interp

    -- ok?
    return interp
end

-- replace macros
function template._replace(macros, macrofiles)

    -- check
    assert(macros and macrofiles)

    -- make all files
    local files = {}
    for _, macrofile in ipairs(table.wrap(macrofiles)) do
        local matchfiles = os.files(macrofile)
        if matchfiles then
            table.join2(files, matchfiles)
        end
    end

    -- replace all files
    for _, file in ipairs(files) do
        for macro, value in pairs(macros) do
            io.gsub(file, "%[" .. macro .. "%]", value)
        end
    end

    -- ok
    return true
end

-- get the language list
function template.languages()

    -- make list
    local list = {}

    -- get the language list 
    local languages = os.dirs(path.join(os.programdir(), "templates", "*"))
    if languages then
        for _, v in ipairs(languages) do
            table.insert(list, path.basename(v))
        end
    end

    -- ok?
    return list
end

-- load all templates from the given language 
function template.templates(language)

    -- check
    assert(language)

    -- get interpreter
    local interp = template._interpreter()
    assert(interp) 

    -- load all templates
    local templates = {}
    local templatefiles = os.files(path.join(os.programdir(), "templates", language, "*", "template.lua"))
    if templatefiles then

        -- load template
        for _, templatefile in ipairs(templatefiles) do

            -- load script
            local ok, errors = interp:load(templatefile)
            if not ok then
                os.raise(errors)
            end

            -- load templates
            local results, errors = interp:make(nil, true, true)
            if not results then
                -- trace
                os.raise(errors)
            end

            -- save template directory
            results:set("_DIRECTORY", path.directory(templatefile))

            -- insert to templates
            table.insert(templates, results:info())
        end
    end
    return templates
end

-- create project from template
function template.create(language, templateid, targetname)

    -- check the language
    if not language then
        return false, "no language!"
    end

    -- check the template id
    if not templateid then
        return false, "no template id!"
    end

    -- get interpreter
    local interp = template._interpreter()
    assert(interp) 

    -- get project directory
    local projectdir = path.absolute(option.get("project") or path.join(os.curdir(), targetname))

    -- set filter
    interp:filter():register("template", function (variable)

        -- init maps
        local maps = 
        {
            targetname  = targetname
        ,   projectdir  = projectdir
        }

        -- map it
        local result = maps[variable]
        if result ~= nil then
            return result
        end

        -- ok?
        return variable

    end)

    -- load all templates for the given language
    local templates = template.templates(language)

    -- TODO: deprecated
    -- in order to be compatible with the old version template
    local templates_old = { quickapp_qt  = "qt.quickapp", 
                            widgetapp_qt = "qt.widgetapp",
                            console_qt   = "qt.console",
                            static_qt    = "qt.static",
                            shared_qt    = "qt.shared",
                            console_tbox = "tbox.console",
                            static_tbox  = "tbox.static",
                            shared_tbox  = "tbox.shared"}
    if templates_old[templateid] then
        deprecated.add("template(" .. templates_old[templateid] .. ")", "template(" .. templateid .. ")")
        templateid = templates_old[templateid]
    end

    -- get the given template module
    local module = nil
    if templates then 
        for _, t in ipairs(templates) do
            if t.name == templateid then
                module = t
                break
            end
        end
    end

    -- load the template module
    if not module then
        return false, string.format("invalid template id: %s!", templateid)
    end

    -- enter the template directory
    if not module._DIRECTORY or not os.cd(module._DIRECTORY) then
        return false, string.format("not found template id: %s!", templateid)
    end

    -- check the template project
    if not module.projectdir or not os.isdir(module.projectdir) then
        return false, string.format("the template project not exists!")
    end
    
    -- ensure the project directory 
    if not os.isdir(projectdir) then 
        os.mkdir(projectdir)
    end

    -- copy the project files
    local ok, errors = os.cp(path.join(module.projectdir, "*"), projectdir) 
    if not ok then
        return false, errors
    end

    -- enter the project directory
    if not os.cd(projectdir) then
        return false, string.format("can not enter %s!", projectdir)
    end

    -- replace macros
    if module.macros and module.macrofiles then
        ok, errors = template._replace(module.macros, module.macrofiles)
        if not ok then
            return false, errors
        end
    end

    -- create project
    if module.create then
        local ok, errors = sandbox.load(module.create)
        if not ok then
            utils.error(errors)
            return false
        end
    end

    -- append FAQ to xmake.lua
    local projectfile = path.join(projectdir, "xmake.lua")
    if os.isfile(projectfile) then
        local file = io.open(projectfile, "a+")
        if file then
            file:print("")
            file:print(template.faq())
            file:close()
        end
    end

    -- generate .gitignore
    os.cp(path.join(os.programdir(), "scripts", "gitignore"), path.join(projectdir, ".gitignore"))

    -- ok
    return true
end

-- get FAQ
function template.faq()
    return [[
--
-- FAQ
--
-- You can enter the project directory firstly before building project.
--   
--   $ cd projectdir
-- 
-- 1. How to build project?
--   
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install 
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code 
--    -- add macro defination
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "cxx11")
--
--    -- set optimization: none, faster, fastest, smallest 
--    set_optimize("fastest")
--    
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox", "z", "pthread")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--
-- 7. If you want to known more usage about xmake, please see http://xmake.io/#/home
--
    ]]
end

-- return module: template
return template
