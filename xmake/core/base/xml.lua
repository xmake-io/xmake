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
-- @author      ruki
-- @file        xml.lua
--

-- define module: xml
local xml = xml or {}

-- load modules
local io    = require("base/io")
local os    = require("base/os")
local table = require("base/table")

function xml._decode_entities(str)
    return (str:gsub("&lt;", "<")
               :gsub("&gt;", ">")
               :gsub("&apos;", "'")
               :gsub("&quot;", "\"")
               :gsub("&amp;", "&"))
end

function xml._encode_text(str)
    return (str:gsub("&", "&amp;")
               :gsub("<", "&lt;")
               :gsub(">", "&gt;"))
end

function xml._encode_attr(str)
    return xml._encode_text(str):gsub("\"", "&quot;")
end

function xml._parse_attrs(attrstr)
    local attrs = {}
    attrstr:gsub("([%w_:%-%.]+)%s*=%s*([\"'])(.-)%2", function(key, quote, value)
        attrs[key] = xml._decode_entities(value)
    end)
    return attrs
end

-- create an xml element node
function xml.new(name, attrs, children)
    return {
        name = name,
        attrs = attrs or {},
        children = children or {}
    }
end

-- create a text node
function xml.text(value)
    return {type = "text", text = value or ""}
end

function xml._append_text(stack, text, opt)
    opt = opt or {}
    if opt.trim_text ~= false then
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
    end
    if text ~= "" then
        local top = stack[#stack]
        top.children = top.children or {}
        table.insert(top.children, {type = "text", text = xml._decode_entities(text)})
    end
end

function xml._handle_closing(stack, tagname)
    local top = stack[#stack]
    if not top or top.name ~= tagname then
        return nil, string.format("malformed xml: unexpected closing </%s>", tagname)
    end
    table.remove(stack)
    return true
end

-- decode xml string to tree node(s)
function xml.decode(data, opt)
    opt = opt or {}
    local root = {name = "__root__", attrs = {}, children = {}}
    local stack = {root}
    local i = 1
    local len = #data
    while i <= len do
        local lt = data:find("<", i, true)
        if not lt then
            local text = data:sub(i)
            xml._append_text(stack, text, opt)
            break
        end
        if lt > i then
            local text = data:sub(i, lt - 1)
            xml._append_text(stack, text, opt)
        end
        if data:sub(lt + 1, lt + 3) == "!--" then
            local close = data:find("-->", lt + 4, true)
            if not close then
                return nil, "unterminated xml comment"
            end
            i = close + 3
        elseif data:sub(lt + 1, lt + 1) == "?" then
            local close = data:find("?>", lt + 2, true)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 2
        elseif data:sub(lt + 1, lt + 1) == "!" then
            local close = data:find(">", lt + 2)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 1
        elseif data:sub(lt + 1, lt + 1) == "/" then
            local close = data:find(">", lt + 1)
            if not close then
                return nil, "unterminated closing tag"
            end
            local tagname = data:sub(lt + 2, close - 1):match("^%s*([^%s>]+)")
            local ok, err = xml._handle_closing(stack, tagname)
            if not ok then
                return nil, err
            end
            i = close + 1
        else
            local close = data:find(">", lt + 1)
            if not close then
                return nil, "unterminated opening tag"
            end
            local inside = data:sub(lt + 1, close - 1)
            local selfclose = inside:find("/%s*$")
            if selfclose then
                inside = inside:gsub("/%s*$", "")
            end
            local tagname, attrstr = inside:match("^%s*([^%s>]+)%s*(.-)%s*$")
            local attrs = xml._parse_attrs(attrstr or "")
            local node = {name = tagname, attrs = attrs, children = {}}
            local top = stack[#stack]
            top.children = top.children or {}
            table.insert(top.children, node)
            if not selfclose then
                table.insert(stack, node)
            end
            i = close + 1
        end
    end
    if #stack ~= 1 then
        return nil, "malformed xml: unclosed tags"
    end
    if #root.children == 1 then
        return root.children[1]
    end
    return root.children
end

function xml._indent(opt, level)
    if not opt.pretty then
        return ""
    end
    local indent = opt.indent or 4
    local indentchar = opt.indentchar or " "
    if type(indent) == "number" then
        return string.rep(indentchar, indent * level)
    end
    return indent:rep(level)
end

function xml._encode_node(node, opt, level)
    opt = opt or {}
    level = level or 0
    if node.type == "text" then
        local indent = xml._indent(opt, level)
        local text = xml._encode_text(tostring(node.text or ""))
        if opt.pretty then
            return indent .. text
        end
        return text
    end
    local attrs = {}
    for k, v in pairs(node.attrs or {}) do
        table.insert(attrs, string.format('%s="%s"', k, xml._encode_attr(tostring(v))))
    end
    table.sort(attrs)
    local open = "<" .. node.name
    if #attrs > 0 then
        open = open .. " " .. table.concat(attrs, " ")
    end
    if not node.children or #node.children == 0 then
        return xml._indent(opt, level) .. open .. "/>"
    end
    local newline = opt.pretty and "\n" or ""
    if #node.children == 1 and node.children[1].type == "text" then
        local text = xml._encode_text(tostring(node.children[1].text or ""))
        return string.format("%s%s>%s</%s>", xml._indent(opt, level), open, text, node.name)
    end
    local result = {}
    table.insert(result, xml._indent(opt, level) .. open .. ">")
    for _, child in ipairs(node.children) do
        table.insert(result, xml._encode_node(child, opt, level + 1))
    end
    table.insert(result, xml._indent(opt, level) .. "</" .. node.name .. ">")
    return table.concat(result, newline ~= "" and newline or "")
end

-- encode xml node to string
function xml.encode(node, opt)
    opt = opt or {}
    return xml._encode_node(node, opt, 0)
end

-- load xml file
function xml.load(filepath, opt)
    local data, err = io.readfile(filepath, opt)
    if not data then
        return nil, err
    end
    return xml.decode(data, opt)
end

-- save xml node to file
function xml.save(filepath, node, opt)
    local data = xml.encode(node, opt)
    if not data then
        return nil, "failed to encode xml"
    end
    return io.writefile(filepath, data, opt)
end

-- find the first child node with the given name
function xml.find(node, name)
    if not node or not node.children then
        return nil
    end
    for _, child in ipairs(node.children) do
        if child.name == name then
            return child
        end
    end
end

-- get concatenated text from child nodes
function xml.text_of(node)
    if not node or not node.children then
        return ""
    end
    local buffer = {}
    for _, child in ipairs(node.children) do
        if child.type == "text" then
            table.insert(buffer, child.text)
        end
    end
    return table.concat(buffer, "")
end

return xml

