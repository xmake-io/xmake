import("core.base.option")
import("lib.lni.test")

function main ()
    print(test)
    print("hello xmake!")
    local argv = option.get("arguments")
    if argv then
        print(argv)
    end
end
