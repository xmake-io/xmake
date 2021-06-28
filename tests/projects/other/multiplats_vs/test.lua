function test_multivs(t)
    if is_subhost("windows") then
        t:build()
    else
        return t:skip("wrong host platform")
    end
end
