function test_are_same(t)
    t:are_same(1, 1)
    t:are_same("1", "1")
    t:are_same(nil, nil)
    t:are_same(true, true)
    t:are_same(1.34, 1.34)
    t:are_same(test_are_same, test_are_same)

    t:are_not_same({}, {})
    t:are_not_same(1, "1")
end

function test_are_equal(t)
    t:are_equal(1, 1)
    t:are_equal("1", "1")
    t:are_equal(nil, nil)
    t:are_equal(true, true)
    t:are_equal(1.34, 1.34)
    t:are_equal(test_are_same, test_are_same)
    t:are_equal({}, {})
    t:are_equal({ a = 1 }, { a = 1 })
    t:are_equal({ a = { a= 1}}, { a = {a=1} })

    t:are_not_equal(1, "1")
    t:are_not_equal({ a = 1 }, { a = 1, b = 2 })
    t:are_not_equal({ a = 1, c = 3 }, { a = 1, b = 2 })
    t:are_not_equal({ a = 1}, { a = 1, b = 2 })
    t:are_not_equal({ a = { a= 1}}, { a = {a=2} })
end


function test_require(t)
    t:require(true)
    t:require({})
    t:require(0)
    t:require("")

    t:require_not(false)
    t:require_not(nil)
end

function test_will_raise(t)
    t:will_raise(function ()
        raise("error: xxx")
    end, "error")
    t:will_raise(function ()
        raise(" ")
    end, "%s")
    t:will_raise(function ()
        raise("")
    end)

    t:will_raise(function ()
        print("A test failed message will be printed")
        t:will_raise(function() end)
    end, "aborting because of ${red}failed assertion${reset}")
end

