import("core.base.option")
function main ()
    print("hello xmake!")
    local argv = option.get("arguments")
    if argv then
        print(argv)
    end
end
