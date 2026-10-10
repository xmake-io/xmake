import("core.base.text")

function test_fixed_width(t)
    t:are_equal(text.table({{"a", "b"}, width={5, 3}, sep="|"}, {plain=true}), "a    |b\n")
    t:are_equal(text.table({{"a", "b"}, width={5, 3}, align="r", sep="|"}, {plain=true}), "    a|  b\n")
    t:are_equal(text.table({{"a", "b"}, width={5, 3}, align="c", sep="|"}, {plain=true}), "  a  | b \n")
end

function test_minimum_width(t)
    t:are_equal(text.table({{"a", "b"}, width={{5, 8}, {3, 8}}, sep="|"}, {plain=true}), "a    |b\n")
    t:are_equal(text.table({{"", "b"}, width={{5, 8}, {3, 8}}, sep="|"}, {plain=true}), "     |b\n")
    t:are_equal(text.table({{"a", "b", align="r"}, width={{5, 8}, {3, 8}}, sep="|"}, {plain=true}), "    a|  b\n")
    t:are_equal(text.table({{"a", "b"}, {"cc", "d"}, width={3, 2}, sep="|"}, {plain=true}), "a  |b\ncc |d\n")
end

function test_minimum_span_width(t)
    t:are_equal(text.table({{"title", nil, "z"}, width={5, 3, 2}, sep="|"}, {plain=true}), "title    |z\n")
end

function test_width_controls(t)
    t:are_equal(text.table({{"a", "b"}, sep="|"}, {plain=true}), "a|b\n")
    t:are_equal(text.table({{"a", "b"}, width={{0, 8}, {0, 8}}, sep="|"}, {plain=true}), "a|b\n")
    t:are_equal(text.table({{"abcdef", "b"}, width={{3, 8}, 3}, sep="|"}, {plain=true}), "abcdef|b\n")
    t:are_equal(text.table({{"ab cd", "b"}, width={{0, 3}, {0, 3}}, sep="|"}, {plain=true}), "ab|b\ncd|\n")
end
