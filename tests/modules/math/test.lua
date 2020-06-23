function test_isinf(t)
    t:will_raise(function() math.isinf(nil) end)
    t:will_raise(function() math.isinf(true) end)

    t:require_not(math.isinf(0))
    t:require_not(math.isinf(math.nan))
    t:are_same(math.isinf(math.inf), 1)
    t:are_same(math.isinf(-math.inf), -1)
end

function test_isnan(t)
    t:will_raise(function() math.isinf(nil) end)
    t:will_raise(function() math.isinf(true) end)

    t:require_not(math.isnan(0))
    t:require(math.isnan(math.nan))
    t:require_not(math.isnan(math.huge))
    t:require_not(math.isnan(-math.huge))
end

function test_isint(t)
    t:will_raise(function() math.isint(nil) end)
    t:will_raise(function() math.isint(true) end)

    t:require(math.isint(0))
    t:require(math.isint(-10))
    t:require(math.isint(123456))
    t:require_not(math.isint(123456.1))
    t:require_not(math.isint(-9.99))
    t:require_not(math.isint(math.nan))
    t:require_not(math.isint(math.huge))
    t:require_not(math.isint(-math.huge))
end

