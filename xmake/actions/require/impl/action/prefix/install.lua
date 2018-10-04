--!The Make-like install Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install.lua
--

-- imports
import("uninstall")

-- copy files to the prefix directory
function _copy(mode, pattern)

    -- do install
    local prefixdir       = _g.prefixdir
    local installdir      = _g.installdir
    local relative_pathes = _g.relative_pathes
    for _, sourcepath in ipairs(os.match(path.join(installdir, pattern), mode)) do

        -- get relative path
        local relative_path = path.relative(sourcepath, installdir)

        -- trace
        vprint("copying %s ..", relative_path)

        -- copy file to the prefix directory
        os.cp(sourcepath, path.absolute(relative_path, prefixdir))

        -- save this relative path
        table.insert(relative_pathes, relative_path)
    end
end

-- copy directories to the prefix directory
function _copy_dirs(pattern)
    _copy('d', pattern)
end

-- copy files to the prefix directory
function _copy_files(pattern)
    _copy('f', pattern)
end

-- copy files and directories to the prefix directory
function _copy_filedirs(pattern)
    _copy('a', pattern)
end

-- do link 
function _do_link(sourcepath, relativepath)

    -- link conflicts?
    local destpath = path.absolute(relativepath, _g.prefixdir)
    if os.islink(destpath) then

        -- get the original path of destpath
        local originpath = os.readlink(destpath)
        if os.isdir(sourcepath) and os.isdir(originpath) then

            -- trace
            vprint("unlinking %s ..", relativepath)

            -- find the prefix info file of the previous package
            local parentdir = path.directory(originpath)
            while parentdir and os.isdir(parentdir) and not os.isfile(path.join(parentdir, "prefixinfo.txt")) do
                parentdir = path.directory(parentdir)
            end

            -- get the prefix info
            local prefixfile = nil
            local prefixinfo = nil
            if parentdir then
                prefixfile = path.join(parentdir, "prefixinfo.txt")
                if os.isfile(prefixfile) then
                    prefixinfo = io.load(prefixfile)
                end
            end
                
            -- remove the previous link
            os.rm(destpath)
            if prefixinfo then
                for idx, installfile in ipairs(prefixinfo.installed) do
                    if installfile == relativepath then
                        table.remove(prefixinfo.installed, idx) 
                        break
                    end
                end
            end

            -- expand and relink the previous directories
            for _, filedir in ipairs(os.filedirs(path.join(originpath, "*"))) do

                -- get file or directory name
                local filename = path.filename(filedir)

                -- trace
                vprint("relinking %s ..", path.join(relativepath, filename))
                
                -- do link
                os.ln(filedir, path.join(destpath, filename))

                -- save this relative path
                table.insert(prefixinfo.installed, path.join(relativepath, filename))
            end

            -- update the previous prefix info file
            if prefixinfo then
                io.save(prefixfile, prefixinfo)
            end

            -- link the child pathes
            for _, filedir in ipairs(os.filedirs(path.join(sourcepath, "*"))) do
                _do_link(filedir, path.join(relativepath, path.filename(filedir)))
            end
        else
            -- link conflicts
            os.raise("cannot link %s => %s", sourcepath, destpath)
        end
    elseif os.isdir(destpath) then

        -- link the child pathes
        for _, filedir in ipairs(os.filedirs(path.join(sourcepath, "*"))) do
            _do_link(filedir, path.join(relativepath, path.filename(filedir)))
        end
    else

        -- trace
        vprint("linking %s ..", relativepath)

        -- do link
        os.ln(sourcepath, destpath)

        -- save this relative path
        table.insert(_g.relative_pathes, relativepath)
    end
end

-- link files to the prefix directory
function _link(mode, pattern)
    local installdir = _g.installdir
    for _, sourcepath in ipairs(os.match(path.join(installdir, pattern), mode)) do
        _do_link(sourcepath, path.relative(sourcepath, installdir))
    end
end

-- link directories to the prefix directory
function _link_dirs(pattern)
    _link('d', pattern)
end

-- link files to the prefix directory
function _link_files(pattern)
    _link('f', pattern)
end

-- link files and directories to the prefix directory
function _link_filedirs(pattern)
    _link('a', pattern)
end

-- install package with link
function _install_with_link(package)
    _link_files("bin/*")
    _link_files("sbin/*")
    _link_filedirs("include/*")
    _link_filedirs("lib/*")
    _link_filedirs("share/*|info")
    _link_filedirs("share/info/*|dir")
end

-- install package without link (windows)
function _install_without_link(package)
    if package:kind() == "binary" then
        _copy_filedirs("**")
    else
        _copy_filedirs("lib/**")
        _copy_filedirs("include/**")
    end
end

-- install package to the prefix directory
function main(package)

    -- init some pathes
    _g.prefixdir       = package:prefixdir()
    _g.installdir      = package:installdir()
    _g.relative_pathes = {}

    -- trace
    vprint("installing %s to %s ..", _g.installdir, _g.prefixdir)

    -- install to the prefix directory
    local relative_pathes = {}
    try
    {
        function ()

            -- install package
            if is_host("windows") then
                _install_without_link(package)
            else
                _install_with_link(package)
            end
        end,
        catch 
        {
            function (errors)
                raise(errors)
            end
        },
        finally
        {
            function ()
                -- save the prefix info to file
                local prefixinfo = package:prefixinfo()
                prefixinfo.installed = _g.relative_pathes
                prefixinfo.prefixdir = _g.prefixdir
                io.save(package:prefixfile(), prefixinfo)

                -- register this package
                package:register()
            end
        }
    }
end

