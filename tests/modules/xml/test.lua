import("core.base.xml")

function test_parse_basic(t)
    local doc = xml.decode([[<?xml version="1.0"?><root id="1"><item>foo</item><item id="2"/></root>]])
    t:are_equal(doc.name, "root")
    t:are_equal(doc.attrs.id, "1")
    t:are_equal(#doc.children, 2)
    t:are_equal(doc.children[1].name, "item")
    t:are_equal(xml.text_of(doc.children[1]), "foo")
    t:are_equal(doc.children[2].attrs.id, "2")
end

function test_encode(t)
    local doc = xml.new("root", {id = "1"}, {
        xml.new("item", {}, {xml.text("foo")}),
        xml.new("item", {id = "2"})
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

