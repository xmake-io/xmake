includes("tbox")

-- enable hash, charset, utf8 modules
for _, name in ipairs({ "hash", "charset", "force-utf8" }) do
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
