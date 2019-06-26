includes("repo")

-- enable hash, charset modules
for _, name in ipairs({"hash", "charset"}) do
    option(name)
        set_default(true)
        after_check(function (option)
            option:enable(true)
        end)
    option_end()
end

-- disable demo
option("demo")
    set_default(false)
option_end()
