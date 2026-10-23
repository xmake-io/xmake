inherit(".test_base")

function main()
    run_tests({compiler = "clang", version = clang_min_ver(), fallbackscanner = true})
end
