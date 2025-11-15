import("core.base.xml")

function test_decode_basic(t)
    local doc = xml.decode([[<?xml version="1.0"?><root id="1"><item>foo</item><item id="2"/></root>]])
    t:are_equal(doc.kind, "element")
    t:are_equal(doc.name, "root")
    t:are_equal(doc.attrs.id, "1")
    t:are_equal(#doc.children, 2)
    t:are_equal(doc.children[1].name, "item")
    t:are_equal(xml.text_of(doc.children[1]), "foo")
    t:are_equal(doc.children[1].attrs, nil)
    t:are_equal(doc.children[2].attrs.id, "2")
end

function test_encode_basic(t)
    local doc = xml.new({
        name = "root",
        attrs = {id = "1"},
        children = {
            xml.new({name = "item", children = {xml.text("foo")}}),
            xml.new({name = "item", attrs = {id = "2"}})
        }
    })
    local compact = xml.encode(doc)
    t:are_equal(compact, '<root id="1"><item>foo</item><item id="2"/></root>')
    local pretty = xml.encode(doc, {pretty = true, indent = 2})
    local expected = table.concat({
        '<root id="1">',
        '  <item>foo</item>',
        '  <item id="2"/>',
        '</root>'
    }, "\n")
    t:are_equal(pretty, expected)
end

function test_encode_special_nodes(t)
    t:are_equal(xml.encode(xml.comment("note")), "<!--note-->")
    t:are_equal(xml.encode(xml.cdata("a < b")), "<![CDATA[a < b]]>")
    t:are_equal(xml.encode(xml.doctype("note SYSTEM \"note.dtd\"")), "<!DOCTYPE note SYSTEM \"note.dtd\">")
    t:are_equal(xml.encode(xml.empty("br")), "<br/>")
end

function test_decode_special_nodes(t)
    local doc = xml.decode([=[<root><!--note--><![CDATA[a < b]]><child/></root>]=])
    t:are_equal(doc.children[1].kind, "comment")
    t:are_equal(doc.children[1].text, "note")
    t:are_equal(doc.children[2].kind, "cdata")
    t:are_equal(doc.children[2].text, "a < b")
    t:are_equal(doc.children[3].name, "child")
    local nodes = xml.decode([=[<!DOCTYPE note SYSTEM "note.dtd"><root/>]=])
    t:are_equal(nodes.kind, "element")
    t:are_equal(nodes.name, "root")
    t:are_equal(nodes.prolog[1].kind, "doctype")
end

function test_load_save(t)
    local tmpdir = os.tmpdir()
    local filepath = path.join(tmpdir, "xml_test.xml")
    local doc = xml.new({
        name = "root",
        attrs = {id = "1"},
        children = {xml.text("hello")}
    })
    assert(xml.save(filepath, doc, {pretty = true}))
    local reloaded = xml.load(filepath)
    t:are_equal(reloaded.name, "root")
    t:are_equal(xml.text_of(reloaded), "hello")
    os.tryrm(filepath)
end

function test_plist_sample(t)
    local plist = [[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2020 tboox. All rights reserved.</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
</dict>
</plist>]]
    local doc = xml.decode(plist)
    t:are_equal(doc.name, "plist")
    t:are_equal(doc.attrs.version, "1.0")
    t:are_equal(doc.prolog[1].kind, "doctype")
    local dict = xml.find(doc, "plist/dict")
    t:are_equal(dict.kind, "element")
    local first_key = dict.children[1]
    t:are_equal(first_key.name, "key")
    t:are_equal(xml.text_of(first_key), "CFBundleDevelopmentRegion")
    local first_value = dict.children[2]
    t:are_equal(first_value.name, "string")
    t:are_equal(xml.text_of(first_value), "$(DEVELOPMENT_LANGUAGE)")
    local last_flag = dict.children[#dict.children]
    t:are_equal(last_flag.name, "true")
end

function test_scan_stop(t)
    local plist = [[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
  </dict>
</plist>]]
    local found
    xml.scan(plist, function(node)
        if node.name == "key" and xml.text_of(node) == "NSPrincipalClass" then
            found = node
            return false
        end
    end)
    t:are_equal(found ~= nil, true)
    t:are_equal(xml.text_of(found), "NSPrincipalClass")
end

function test_find_xpath(t)
    local doc = xml.decode([[
<root>
  <items>
    <item id="a"><value>foo</value></item>
    <item id="b"><value>bar</value></item>
  </items>
  <extras>
    <item id="c"/>
  </extras>
</root>]])
    local second = xml.find(doc, "root/items/item[2]")
    t:are_equal(second.attrs.id, "b")
    local descendant = xml.find(doc, "//item[@id='c']")
    t:are_equal(descendant.attrs.id, "c")
    local value = xml.find(doc, "//value[text()='bar']")
    t:are_equal(xml.text_of(value), "bar")
end

function test_find_update(t)
    local doc = xml.decode("<root><item id='a'>foo</item><item id='b'/></root>")
    local target = xml.find(doc, "//item[@id='a']")
    t:are_not_equal(target, nil)
    target.attrs.lang = "en"
    target.children = {xml.text("bar")}
    local new_item = xml.new({name = "item", attrs = {id = "c"}, children = {xml.text("baz")}})
    table.insert(doc.children, new_item)
    local encoded = xml.encode(doc)
    t:are_equal(encoded, '<root><item id="a" lang="en">bar</item><item id="b"/><item id="c">baz</item></root>')
end

function test_decode_trim_text(t)
    local doc = xml.decode("<root>  foo  </root>")
    t:are_equal(xml.text_of(doc), "  foo  ")
    local trimmed = xml.decode("<root>  foo  </root>", {trim_text = true})
    t:are_equal(xml.text_of(trimmed), "foo")
    local formatted = "<root>\n  <item/>\n</root>"
    local default = xml.decode(formatted)
    t:are_equal(#default.children, 1)
    local keep_ws = xml.decode(formatted, {keep_whitespace_nodes = true})
    t:are_equal(#keep_ws.children, 3)
    t:are_equal(keep_ws.children[1].kind, "text")
end

