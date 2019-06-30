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
-- @file        xmake.lua
--


-- define rule: protobuf-cpp 
rule("protobuf.env")

    -- load protoc
    before_load(function (target)
        import("lib.detect.find_tool")
        local protoc = target:data("protobuf.protoc")
        if not protoc then
            protoc = find_tool("protoc") 
            if protoc and protoc.program then
                target:data_set("protobuf.protoc", protoc.program)
            else
                raise("protoc not found!")
            end
        end
    end)

-- define rule: protobuf.cpp 
rule("protobuf.cpp")

    -- add deps
    add_deps("protobuf.env")

    -- set extension
    set_extensions(".proto")

    -- build protobuf file
    on_build_file(function (target, sourcefile_proto, opt)
        import("proto")(target, "cxx", sourcefile_proto, opt)
    end)


-- define rule: protobuf.c 
rule("protobuf.c")

    -- add deps
    add_deps("protobuf.env")

    -- set extension
    set_extensions(".proto")

    -- build protobuf file
    on_build_file(function (target, sourcefile_proto, opt)
        import("proto")(target, "cc", sourcefile_proto, opt)
    end)
