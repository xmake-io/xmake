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