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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        lib.lua
--

-- init it
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "lib.exe"

    -- save the tool kind
    _g.kind = kind or "ar"

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- extract the static library to object directory
function extract(libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- list object files 
    local objectfiles = os.iorun("%s -nologo -list %s", _g.shellname, libraryfile)

    -- extrace all object files
    for _, objectfile in ipairs(objectfiles:split('\n')) do

        -- is object file?
        if objectfile:find("%.obj") then

            -- make the outputfile
            local outputfile = path.translate(format("%s\\%s", objectdir, path.filename(objectfile)))

            -- repeat? rename it
            if os.isfile(outputfile) then
                for i = 0, 10 do
                    outputfile = path.translate(format("%s\\%d_%s", objectdir, i, path.filename(objectfile)))
                    if not os.isfile(outputfile) then 
                        break
                    end
                end
            end

            -- extract it
            os.run("%s -nologo -extract:%s -out:%s %s", _g.shellname, objectfile, outputfile, libraryfile)
        end
    end
end

-- run command
function run(...)

    -- extract it
    if _g.kind == "ex" then
        return extract(...)
    end

    -- run it
    os.run(...)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local libfile = path.join(os.tmpdir(), "xmake.lib.lib")
    local objfile = path.join(os.tmpdir(), "xmake.lib.obj")
    local srcfile = path.join(os.tmpdir(), "xmake.lib.c")
    io.write(srcfile, "int test(void)\n{return 0;}")

    -- check it
    os.run("cl -c -Fo%s %s", objfile, srcfile)
    os.run("link -lib -out:%s %s", libfile, objfile)
    os.run("%s %s -list %s", _g.shellname, ifelse(flags, flags, ""), libfile)

    -- remove files
    os.rm(objfile)
    os.rm(srcfile)
    os.rm(libfile)
end

