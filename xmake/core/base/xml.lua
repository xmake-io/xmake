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

-- XML node structure:
-- {
--     name     = "element-name" | nil (for non-element nodes)
--     kind     = "element" | "text" | "comment" | "cdata" | "doctype" | "document"
--     attrs    = { key = value, ... } or nil (only for elements)
--     text     = "raw text" (for text/comment/cdata/doctype nodes)
--     children = { child1, child2, ... } or nil (for elements or document nodes)
--     prolog   = { comment/doctypes before root } or nil (only on root element)
-- }
--
-- Example:
--   local doc = xml.decode("<root id='1'><item>foo</item><!--note--></root>")
--   doc.kind == "element"
--   doc.attrs.id == "1"
--   xml.find(doc, "root/item").kind == "element"
--   xml.text_of(doc) == ""       -- since root has no direct text nodes
--   doc.prolog[1].kind == "doctype" -- e.g. when document had <!DOCTYPE ...>
--   doc.children[2].kind == "comment" and doc.children[2].text == "note"
--

-- decode entities
function xml._decode_entities(str)
    return (str:gsub("&lt;", "<")
               :gsub("&gt;", ">")
               :gsub("&apos;", "'")
               :gsub("&quot;", "\"")
               :gsub("&amp;", "&"))
end

-- encode raw text for xml element content
function xml._encode_text(str)
    return (str:gsub("&", "&amp;")
               :gsub("<", "&lt;")
               :gsub(">", "&gt;"))
end

-- encode attribute value for xml output
function xml._encode_attr(str)
    return xml._encode_text(str):gsub("\"", "&quot;")
end

-- parse attribute string to table (or nil if empty)
function xml._parse_attrs(attrstr)
    local attrs
    attrstr:gsub("([%w_:%-%.]+)%s*=%s*([\"'])(.-)%2", function(key, quote, value)
        attrs = attrs or {}
        attrs[key] = xml._decode_entities(value)
    end)
    return attrs
end

-- trim helper
function xml._trim(str)
    return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- iterate element children and optional prolog nodes
function xml._each_child(node, callback)
    if not node or not callback then
        return
    end
    if node.children then
        for _, child in ipairs(node.children) do
            callback(child)
        end
    end
    if node.prolog then
        for _, child in ipairs(node.prolog) do
            callback(child)
        end
    end
end

-- collect descendants that match predicate
function xml._collect_descendants(node, matcher, results)
    results = results or {}
    xml._each_child(node, function(child)
        if matcher(child) then
            table.insert(results, child)
        end
        xml._collect_descendants(child, matcher, results)
    end)
    return results
end

-- parse xpath expression into steps
function xml._parse_xpath(path)
    local steps = {}
    local len = #path
    local i = 1
    local first = true
    while i <= len do
        local axis
        if path:sub(i, i + 1) == "//" then
            axis = "descendant"
            i = i + 2
        elseif path:sub(i, i) == "/" then
            axis = "child"
            i = i + 1
        elseif first then
            axis = "self"
        else
            axis = "child"
        end
        while path:sub(i, i) == "/" do
            if path:sub(i, i + 1) == "//" then
                axis = "descendant"
                i = i + 2
            else
                axis = "child"
                i = i + 1
            end
        end
        if i > len then
            break
        end
        local start = i
        local depth = 0
        while i <= len do
            local ch = path:sub(i, i)
            if ch == "[" then
                depth = depth + 1
            elseif ch == "]" then
                depth = depth - 1
            elseif ch == "/" and depth == 0 then
                break
            end
            i = i + 1
        end
        local segment = xml._trim(path:sub(start, i - 1))
        if segment ~= "" then
            local step = xml._parse_xpath_segment(segment, axis)
            table.insert(steps, step)
        end
        first = false
    end
    return steps
end

-- parse a single xpath step
function xml._parse_xpath_segment(segment, axis)
    local step = {axis = axis or "child", predicates = {}}
    local name = segment:gsub("%b[]", "")
    name = xml._trim(name)
    if name == "" or name == "*" then
        step.node_test = "any"
    elseif name == "." then
        step.node_test = "self"
    elseif name == "text()" then
        step.node_test = "text"
    elseif name == "comment()" then
        step.node_test = "comment"
    elseif name == "cdata()" then
        step.node_test = "cdata"
    elseif name == "doctype()" then
        step.node_test = "doctype"
    else
        step.node_test = "name"
        step.name = name
    end
    for predicate in segment:gmatch("%b[]") do
        local expr = xml._trim(predicate:sub(2, -2))
        if expr ~= "" then
            local number_index = tonumber(expr)
            if number_index then
                step.indexes = step.indexes or {}
                table.insert(step.indexes, number_index)
            else
                local attr_key, quote, attr_value = expr:match("^@([%w_:%-%.]+)%s*=%s*(['\"])(.-)%2$")
                if attr_key then
                    table.insert(step.predicates, {type = "attr", key = attr_key, value = attr_value})
                else
                    local attr_exists = expr:match("^@([%w_:%-%.]+)%s*$")
                    if attr_exists then
                        table.insert(step.predicates, {type = "attr_exists", key = attr_exists})
                    else
                        local text_value = expr:match("^text%(%s*%)%s*=%s*\"(.-)\"$")
                        if not text_value then
                            text_value = expr:match("^text%(%s*%)%s*=%s*'(.-)'$")
                        end
                        if text_value then
                            table.insert(step.predicates, {type = "text", value = text_value})
                        else
                            step.unsupported = true
                        end
                    end
                end
            end
        end
    end
    return step
end

-- check whether node matches xpath step
function xml._match_xpath_node(node, step)
    if step.unsupported then
        return false
    end
    local nodetype = step.node_test or "name"
    if nodetype == "self" then
        -- always match, predicates will refine
    elseif nodetype == "any" then
        -- match every node
    elseif nodetype == "node" then
        -- unused for now
    elseif nodetype == "text" then
        if node.kind ~= "text" then
            return false
        end
    elseif nodetype == "comment" then
        if node.kind ~= "comment" then
            return false
        end
    elseif nodetype == "cdata" then
        if node.kind ~= "cdata" then
            return false
        end
    elseif nodetype == "doctype" then
        if node.kind ~= "doctype" then
            return false
        end
    else
        if node.kind ~= "element" then
            return false
        end
        if step.name and step.name ~= "*" and node.name ~= step.name then
            return false
        end
    end
    if step.predicates then
        for _, predicate in ipairs(step.predicates) do
            if predicate.type == "attr" then
                if not node.attrs or node.attrs[predicate.key] ~= predicate.value then
                    return false
                end
            elseif predicate.type == "attr_exists" then
                if not node.attrs or node.attrs[predicate.key] == nil then
                    return false
                end
            elseif predicate.type == "text" then
                if xml.text_of(node) ~= predicate.value then
                    return false
                end
            end
        end
    end
    return true
end

-- apply positional predicates
function xml._apply_xpath_indexes(nodes, indexes)
    if not indexes or #indexes == 0 then
        return nodes
    end
    local current = nodes
    for _, index in ipairs(indexes) do
        local selected = current[index]
        if not selected then
            return {}
        end
        current = {selected}
    end
    return current
end

-- append normalized text node to top element on stack
function xml._append_text(stack, text, opt)
    opt = opt or {}
    if opt.trim_text ~= false then
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
    end
    if text ~= "" then
        local top = stack[#stack]
        top.children = top.children or {}
        table.insert(top.children, xml.text(xml._decode_entities(text)))
    end
end

-- ensure closing tag matches stack and pop it
function xml._handle_closing(stack, tagname)
    local top = stack[#stack]
    if not top or top.name ~= tagname then
        return nil, string.format("malformed xml: unexpected closing </%s>", tagname)
    end
    table.remove(stack)
    return top
end

-- compute indent string for pretty output
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
    if node.kind == "document" then
        local parts = {}
        if node.children then
            for _, child in ipairs(node.children) do
                table.insert(parts, xml._encode_node(child, opt, level))
            end
        end
        return table.concat(parts, opt.pretty and "\n" or "")
    elseif node.kind == "text" then
        local indent = xml._indent(opt, level)
        local text = xml._encode_text(tostring(node.text or ""))
        if opt.pretty then
            return indent .. text
        end
        return text
    elseif node.kind == "comment" then
        return xml._indent(opt, level) .. string.format("<!--%s-->", tostring(node.text or ""))
    elseif node.kind == "cdata" then
        return xml._indent(opt, level) .. string.format("<![CDATA[%s]]>", tostring(node.text or ""))
    elseif node.kind == "doctype" then
        return xml._indent(opt, level) .. string.format("<!DOCTYPE %s>", tostring(node.text or ""))
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
    if #node.children == 1 and node.children[1].kind == "text" then
        local text = xml._encode_text(tostring(node.children[1].text or ""))
        return string.format("%s%s>%s</%s>", xml._indent(opt, level), open, text, node.name)
    end
    local result = {}
    table.insert(result, xml._indent(opt, level) .. open .. ">")
    if node.children then
        for _, child in ipairs(node.children) do
            table.insert(result, xml._encode_node(child, opt, level + 1))
        end
    end
    table.insert(result, xml._indent(opt, level) .. "</" .. node.name .. ">")
    return table.concat(result, newline ~= "" and newline or "")
end

-- create an xml element node
-- e.g. `local node = xml.new({name = "item", attrs = {id = "1"}, children = {xml.text("value")}})`
--
-- @param opt    table with name/attrs/children/kind/text fields
-- @return       node table
--
function xml.new(opt)
    opt = opt or {}
    return {
        name = opt.name,
        attrs = opt.attrs,
        kind = opt.kind or "element",
        text = opt.text,
        children = opt.children
    }
end

-- create a text node
-- e.g. `local textnode = xml.text("hello")`
--
-- @param value  string content
-- @return       text node
--
function xml.text(value)
    return xml.new({kind = "text", text = value or ""})
end

-- create an empty element node
-- e.g. `local br = xml.empty("br", {class = "line"})`
--
-- @param name   element name
-- @param attrs  attribute table
-- @return       element node
--
function xml.empty(name, attrs)
    return xml.new({name = name, attrs = attrs})
end

-- create a comment node
-- e.g. `local comment = xml.comment("generated by xmake")`
--
-- @param value  comment text
-- @return       comment node
--
function xml.comment(value)
    return xml.new({kind = "comment", text = value or ""})
end

-- create a cdata node
-- e.g. `local cdata = xml.cdata("if (a < b) { ... }")`
--
-- @param value  cdata text
-- @return       cdata node
--
function xml.cdata(value)
    return xml.new({kind = "cdata", text = value or ""})
end

-- create a doctype node
-- e.g. `local doc = xml.doctype('html')`
--
-- @param value  doctype payload
-- @return       doctype node
--
function xml.doctype(value)
    return xml.new({kind = "doctype", text = value or ""})
end

-- decode xml string to tree node(s)
-- e.g. `local doc, err = xml.decode("<root><item>foo</item></root>")`
--
-- @param data   xml string
-- @param opt    options (trim_text, etc.)
-- @return       root node or list on success, nil + error on failure
--
function xml.decode(data, opt)
    opt = opt or {}
    local root_children = {}
    local doc_node = {kind = "document", children = root_children}
    local stack = {doc_node}
    local function ensure_children(node)
        if not node.children then
            if node == doc_node then
                node.children = root_children
            else
                node.children = {}
            end
        end
        return node.children
    end
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
            local value = data:sub(lt + 4, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            table.insert(children, xml.comment(value))
            i = close + 3
        elseif data:sub(lt + 1, lt + 8) == "![CDATA[" then
            local close = data:find("]]>", lt + 9, true)
            if not close then
                return nil, "unterminated cdata section"
            end
            local value = data:sub(lt + 9, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            table.insert(children, xml.cdata(value))
            i = close + 3
        elseif data:sub(lt + 1, lt + 8):upper() == "!DOCTYPE" then
            local close = data:find(">", lt + 8, true)
            if not close then
                return nil, "unterminated doctype declaration"
            end
            local value = data:sub(lt + 9, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            table.insert(children, xml.doctype(value))
            i = close + 1
        elseif data:sub(lt + 1, lt + 1) == "?" then
            local close = data:find("?>", lt + 2, true)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 2
        elseif data:sub(lt + 1, lt + 1) == "!" then
            local close = data:find(">", lt + 2, true)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 1
        elseif data:sub(lt + 1, lt + 1) == "/" then
            local close = data:find(">", lt + 1, true)
            if not close then
                return nil, "unterminated closing tag"
            end
            local tagname = data:sub(lt + 2, close - 1):match("^%s*([^%s>]+)")
            local node, err = xml._handle_closing(stack, tagname)
            if not node then
                return nil, err
            end
            i = close + 1
        else
            local close = data:find(">", lt + 1, true)
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
            local node = xml.empty(tagname, attrs)
            local top = stack[#stack]
            local children = ensure_children(top)
            table.insert(children, node)
            if not selfclose then
                table.insert(stack, node)
            end
            i = close + 1
        end
    end
    if #stack ~= 1 then
        return nil, "malformed xml: unclosed tags"
    end
    local element_nodes = {}
    for _, child in ipairs(root_children) do
        if child.kind == "element" then
            table.insert(element_nodes, child)
        end
    end
    if #element_nodes == 1 then
        local rootnode = element_nodes[1]
        local prolog = {}
        for _, child in ipairs(root_children) do
            if child ~= rootnode then
                table.insert(prolog, child)
            end
        end
        if #prolog > 0 then
            rootnode.prolog = prolog
        end
        return rootnode
    end
    return root_children
end

-- stream parse xml data
--
-- @param data        xml string
-- @param callback    function(node) -> true|false (return false to stop scanning)
-- @param opt         options (trim_text, etc.)
-- @return            true on success or nil, error on failure
--
function xml.scan(data, callback, opt)
    opt = opt or {}
    local root_children = {}
    local doc_node = {kind = "document", children = root_children}
    local stack = {doc_node}
    local stop = false
    local function ensure_children(node)
        if not node.children then
            if node == doc_node then
                node.children = root_children
            else
                node.children = {}
            end
        end
        return node.children
    end
    local function emit(node)
        if callback and node.kind ~= "document" then
            if callback(node) == false then
                stop = true
            end
        end
    end
    local i = 1
    local len = #data
    while i <= len do
        if stop then
            break
        end
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
            local value = data:sub(lt + 4, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            local node = xml.comment(value)
            table.insert(children, node)
            emit(node)
            i = close + 3
        elseif data:sub(lt + 1, lt + 8) == "![CDATA[" then
            local close = data:find("]]>", lt + 9, true)
            if not close then
                return nil, "unterminated cdata section"
            end
            local value = data:sub(lt + 9, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            local node = xml.cdata(value)
            table.insert(children, node)
            emit(node)
            i = close + 3
        elseif data:sub(lt + 1, lt + 8):upper() == "!DOCTYPE" then
            local close = data:find(">", lt + 8, true)
            if not close then
                return nil, "unterminated doctype declaration"
            end
            local value = data:sub(lt + 9, close - 1)
            local top = stack[#stack]
            local children = ensure_children(top)
            local node = xml.doctype(value)
            table.insert(children, node)
            emit(node)
            i = close + 1
        elseif data:sub(lt + 1, lt + 1) == "?" then
            local close = data:find("?>", lt + 2, true)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 2
        elseif data:sub(lt + 1, lt + 1) == "!" then
            local close = data:find(">", lt + 2, true)
            if not close then
                return nil, "unterminated xml declaration"
            end
            i = close + 1
        elseif data:sub(lt + 1, lt + 1) == "/" then
            local close = data:find(">", lt + 1, true)
            if not close then
                return nil, "unterminated closing tag"
            end
            local tagname = data:sub(lt + 2, close - 1):match("^%s*([^%s>]+)")
            local node, err = xml._handle_closing(stack, tagname)
            if not node then
                return nil, err
            end
            emit(node)
            i = close + 1
        else
            local close = data:find(">", lt + 1, true)
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
            local node = xml.empty(tagname, attrs)
            local top = stack[#stack]
            local children = ensure_children(top)
            table.insert(children, node)
            if not selfclose then
                table.insert(stack, node)
            else
                emit(node)
            end
            i = close + 1
        end
    end
    return true
end

-- encode xml node to string
-- e.g. `local xmlstr = xml.encode(node, {pretty = true, indent = 2})`
--
-- @param node   xml node
-- @param opt    options (pretty, indent, etc.)
-- @return       xml string or nil, err
--
function xml.encode(node, opt)
    opt = opt or {}
    local fragments = {}
    local prolog = node.prolog
    if prolog then
        for _, child in ipairs(prolog) do
            table.insert(fragments, xml._encode_node(child, opt, 0))
            if opt.pretty then
                table.insert(fragments, "\n")
            end
        end
    end
    table.insert(fragments, xml._encode_node(node, opt, 0))
    return table.concat(fragments)
end

-- load xml file
-- e.g. `local doc, err = xml.load("foo.xml")`
--
-- @param filepath  file path
-- @param opt       read/decode options
-- @return          node or nil + error
--
function xml.load(filepath, opt)
    local data, err = io.readfile(filepath, opt)
    if not data then
        return nil, err
    end
    return xml.decode(data, opt)
end

-- save xml node to file
-- e.g. `assert(xml.save("foo.xml", node, {pretty = true}))`
--
-- @param filepath  destination file
-- @param node      xml node
-- @param opt       encode/write options
-- @return          true on success or nil + error message
--
function xml.save(filepath, node, opt)
    local data = xml.encode(node, opt)
    if not data then
        return nil, "failed to encode xml"
    end
    return io.writefile(filepath, data, opt)
end

-- find the first matching node with an XPath-like expression
-- e.g. `xml.find(doc, "//dict/key[@name='CFBundleName']")`
--
-- Supported syntax:
--   - `/` child axis, `//` descendant-or-self axis
--   - `*`, `text()`, `comment()`, `cdata()`, `doctype()`, `.`
--   - Attribute predicates: `[@id='foo']`, `[@enabled]`
--   - Text predicate: `[text()='value']`
--   - Positional predicate: `[2]`
--
-- @param node   root node
-- @param path   xpath-like string
-- @return       first matched node or nil
--
function xml.find(node, path)
    if not node or not path or path == "" then
        return nil
    end
    local steps = xml._parse_xpath(path)
    if #steps == 0 then
        return nil
    end
    local current
    if path:sub(1, 1) == "/" then
        current = {{kind = "document", children = {node}}}
    else
        current = {node}
    end
    for _, step in ipairs(steps) do
        local matches = {}
        if step.axis == "self" then
            for _, candidate in ipairs(current) do
                if xml._match_xpath_node(candidate, step) then
                    table.insert(matches, candidate)
                end
            end
        elseif step.axis == "child" then
            for _, parent in ipairs(current) do
                xml._each_child(parent, function(child)
                    if xml._match_xpath_node(child, step) then
                        table.insert(matches, child)
                    end
                end)
            end
        elseif step.axis == "descendant" then
            for _, parent in ipairs(current) do
                if xml._match_xpath_node(parent, step) then
                    table.insert(matches, parent)
                end
                xml._collect_descendants(parent, function(desc)
                    return xml._match_xpath_node(desc, step)
                end, matches)
            end
        else
            return nil
        end
        matches = xml._apply_xpath_indexes(matches, step.indexes)
        if #matches == 0 then
            return nil
        end
        current = matches
    end
    return current[1]
end

-- get concatenated text from child nodes
-- e.g. `local text = xml.text_of(xml.decode("<item>foo</item>"))`
--
-- @param node   xml node
-- @return       concatenated string
--
function xml.text_of(node)
    if not node or not node.children then
        return ""
    end
    local buffer = {}
    for _, child in ipairs(node.children) do
        if child.kind == "text" then
            table.insert(buffer, child.text or "")
        end
    end
    return table.concat(buffer, "")
end

return xml

