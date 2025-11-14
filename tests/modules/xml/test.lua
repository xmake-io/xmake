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

