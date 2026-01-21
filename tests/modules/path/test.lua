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

function test_filename(t)
    t:are_equal(path.filename("foo"), "foo")
    t:are_equal(path.filename("foo.so"), "foo.so")
    t:are_equal(path.filename("/tmp/foo.so"), "foo.so")
    t:are_equal(path.filename("c:\\tmp\\foo.so"), "foo.so")
    t:are_equal(path.filename("/tmp/.."), "..")
    t:are_equal(path.filename("/tmp/."), ".")
    t:are_equal(path.filename("/"), "")
    t:are_equal(path.filename(""), "")
    
    -- unicode
    t:are_equal(path.filename("Unicode 测试/test.lua"), "test.lua")
    t:are_equal(path.filename("Unicode 测试/foo/test.lua"), "test.lua")
    t:are_equal(path.filename("测试/test.lua"), "test.lua")
    t:are_equal(path.filename("测试\\test.lua"), "test.lua")
end

function test_directory(t)
    t:are_equal(path.directory(""), nil)
    t:are_equal(path.directory("."), nil)
    t:are_equal(path.directory("foo"), ".")
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
    if is_host("windows") then
        t:are_equal(path.translate("c:"), "c:")
        t:are_equal(path.translate("c:\\"), "c:")
        t:are_equal(path.translate("c:\\foo\\\\\\"), "c:\\foo")
        t:are_equal(path.translate("c:\\foo\\..\\.."), "c:\\foo\\..\\..")
    else
        t:are_equal(path.translate("/"), "/");
        t:are_equal(path.translate("////"), "/");
        t:are_equal(path.translate("/foo//////"), "/foo");
        t:are_equal(path.translate("/foo/../.."), "/foo/../..");
        t:are_equal(path.translate("/foo/../../"), "/foo/../..");
    end
end

function test_normalize(t)
    t:are_equal(path.normalize("././."), ".")
    t:are_equal(path.normalize("../foo/.."), "..")
    t:are_equal(path.normalize("../foo/bar/../.."), "..")
    if is_host("windows") then
        t:are_equal(path.normalize("c:\\foo\\.\\.\\"), "c:\\foo")
        t:are_equal(path.normalize("c:\\foo\\bar\\.\\..\\xyz"), "c:\\foo\\xyz")
        t:are_equal(path.normalize("c:\\foo\\.\\.."), "c:")
        t:are_equal(path.normalize("../.."), "..\\..")
        t:are_equal(path.normalize("../foo/bar/.."), "..\\foo")
        t:are_equal(path.normalize("../foo/bar/../../.."), "..\\..")
    else
        t:are_equal(path.normalize("/foo/././"), "/foo");
        t:are_equal(path.normalize("/./././"), "/");
        t:are_equal(path.normalize("/foo/bar/.//..//xyz"), "/foo/xyz");
        t:are_equal(path.normalize("/foo/../.."), "/");
        t:are_equal(path.normalize("/foo/bar../.."), "/foo");
        t:are_equal(path.normalize("../.."), "../..");
        t:are_equal(path.normalize("../foo/bar/.."), "../foo");
        t:are_equal(path.normalize("../foo/bar/../../.."), "../..");
    end
end

function test_instance(t)
    t:are_equal(path("/tmp/a"):str(), "/tmp/a")
    t:are_equal(path("/tmp/a"):directory():str(), "/tmp")
    t:are_equal(path("/tmp/a", function (p) return "--key=" .. p end):str(), "--key=/tmp/a")
    t:are_equal(path("/tmp/a", function (p) return "--key=" .. p end):rawstr(), "/tmp/a")
    t:are_equal(path("/tmp/a", function (p) return "--key=" .. p end):clone():set("/tmp/b"):str(), "--key=/tmp/b")
end
