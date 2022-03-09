function test_splitenv_win(t)
    if not is_host("windows") then
        return t:skip("wrong host platform")
    end
    t:are_equal(path.splitenv(""), {})
    t:are_equal(path.splitenv("a"), {'a'})
    t:are_equal(path.splitenv("a;b"), {'a','b'})
    t:are_equal(path.splitenv(";;a;;b;"), {'a','b'})
    t:are_equal(path.splitenv('c:/a;c:\\b'), {'c:/a', 'c:\\b'})
    t:are_equal(path.splitenv('"a;aa;aa;;"'), {"a;aa;aa;;"})
    t:are_equal(path.splitenv('"a;aa;aa;;";bb;;'), {"a;aa;aa;;", 'bb'})
    t:are_equal(path.splitenv('"a;aa;aa;;";"a;cc;aa;;";bb;"d";'), {"a;aa;aa;;","a;cc;aa;;", 'bb', 'd' })
end

function test_splitenv_unix(t)
    if is_host("windows") then
        return t:skip("wrong host platform")
    end
    t:are_equal(path.splitenv(""), {})
    t:are_equal(path.splitenv("a"), {'a'})
    t:are_equal(path.splitenv("a:b"), {'a','b'})
    t:are_equal(path.splitenv("::a::b:"), {'a','b'})
    t:are_equal(path.splitenv('a%tag:b'), {'a','b'})
    t:are_equal(path.splitenv('a%tag:b%tag'), {'a','b'})
    t:are_equal(path.splitenv('a%tag:b%%tag%%'), {'a','b'})
    t:are_equal(path.splitenv('a%tag:b:%tag:'), {'a','b'})
end

function test_extension(t)
    t:are_equal(path.extension("1.1/abc"), "")
    t:are_equal(path.extension("1.1\\abc"), "")
    t:are_equal(path.extension("foo.so"), ".so")
    t:are_equal(path.extension("/home/foo.so"), ".so")
    t:are_equal(path.extension("\\home\\foo.so"), ".so")
end

function test_directory(t)
    t:are_equal(path.directory(""), nil)
    t:are_equal(path.directory("."), nil)
    if is_host("windows") then
        t:are_equal(path.directory("c:"), nil)
        t:are_equal(path.directory("c:\\"), nil)
        t:are_equal(path.directory("c:\\xxx"), "c:")
        t:are_equal(path.directory("c:\\xxx\\yyy"), "c:\\xxx")
    else
        t:are_equal(path.directory("/tmp"), "/")
        t:are_equal(path.directory("/tmp/"), "/")
        t:are_equal(path.directory("/tmp/xxx"), "/tmp")
        t:are_equal(path.directory("/tmp/xxx/"), "/tmp")
        t:are_equal(path.directory("/"), nil)
    end
end

function test_absolute(t)
    t:are_equal(path.absolute("", ""), nil)
    t:are_equal(path.absolute(".", "."), ".")
    if is_host("windows") then
        t:are_equal(path.absolute("foo", "c:"), "c:\\foo")
        t:are_equal(path.absolute("foo", "c:\\"), "c:\\foo")
        t:are_equal(path.absolute("foo", "c:\\tmp"), "c:\\tmp\\foo")
        t:are_equal(path.absolute("foo", "c:\\tmp\\"), "c:\\tmp\\foo")
    else
        t:are_equal(path.absolute("", "/"), nil)
        t:are_equal(path.absolute("/", "/"), "/")
        t:are_equal(path.absolute(".", "/"), "/")
        t:are_equal(path.absolute("foo", "/tmp/"), "/tmp/foo")
        t:are_equal(path.absolute("foo", "/tmp"), "/tmp/foo")
    end
end

function test_relative(t)
    t:are_equal(path.relative("", ""), nil)
    t:are_equal(path.relative(".", "."), ".")
    if is_host("windows") then
        t:are_equal(path.relative("c:", "c:\\"), ".")
        t:are_equal(path.relative("c:\\foo", "c:\\foo"), ".")
        t:are_equal(path.relative("c:\\foo", "c:\\"), "foo")
        t:are_equal(path.relative("c:\\tmp\\foo", "c:\\tmp"), "foo")
        t:are_equal(path.relative("c:\\tmp\\foo", "c:\\tmp\\"), "foo")
    else
        t:are_equal(path.relative("", "/"), nil)
        t:are_equal(path.relative("/", "/"), ".")
        t:are_equal(path.relative("/tmp/foo", "/tmp/"), "foo")
        t:are_equal(path.relative("/tmp/foo", "/tmp"), "foo")
    end
end

function test_translate(t)
    t:are_equal(path.translate(""), nil)
    t:are_equal(path.translate("."), ".")
    t:are_equal(path.translate(".."), "..")
    t:are_equal(path.translate("././."), ".")
    t:are_equal(path.translate("../foo/..", {reduce_dot2 = true}), "..")
    t:are_equal(path.translate("../foo/bar/../..", {reduce_dot2 = true}), "..")
    if is_host("windows") then
        t:are_equal(path.translate("c:"), "c:")
        t:are_equal(path.translate("c:\\"), "c:")
        t:are_equal(path.translate("c:\\foo\\.\\.\\"), "c:\\foo")
        t:are_equal(path.translate("c:\\foo\\\\\\"), "c:\\foo")
        t:are_equal(path.translate("c:\\foo\\..\\.."), "c:\\foo\\..\\..")
        t:are_equal(path.translate("c:\\foo\\bar\\.\\..\\xyz", {reduce_dot2 = true}), "c:\\foo\\xyz")
        t:are_equal(path.translate("c:\\foo\\.\\..", {reduce_dot2 = true}), "c:")
        t:are_equal(path.translate("../..", {reduce_dot2 = true}), "..\\..")
        t:are_equal(path.translate("../foo/bar/..", {reduce_dot2 = true}), "..\\foo")
        t:are_equal(path.translate("../foo/bar/../../..", {reduce_dot2 = true}), "..\\..")
    else
        t:are_equal(path.translate("/"), "/");
        t:are_equal(path.translate("////"), "/");
        t:are_equal(path.translate("/./././"), "/");
        t:are_equal(path.translate("/foo/././"), "/foo");
        t:are_equal(path.translate("/foo//////"), "/foo");
        t:are_equal(path.translate("/foo/../.."), "/foo/../..");
        t:are_equal(path.translate("/foo/../../"), "/foo/../..");
        t:are_equal(path.translate("/foo/bar/.//..//xyz", {reduce_dot2 = true}), "/foo/xyz");
        t:are_equal(path.translate("/foo/../..", {reduce_dot2 = true}), "/");
        t:are_equal(path.translate("/foo/bar../..", {reduce_dot2 = true}), "/foo");
        t:are_equal(path.translate("../..", {reduce_dot2 = true}), "../..");
        t:are_equal(path.translate("../foo/bar/..", {reduce_dot2 = true}), "../foo");
        t:are_equal(path.translate("../foo/bar/../../..", {reduce_dot2 = true}), "../..");
    end
end

