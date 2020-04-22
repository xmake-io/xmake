import("core.base.option")
import("lib.lni")

function main ()
    print(lni)
    print("hello xmake!")
    local argv = option.get("arguments")
    if argv then
        print(argv)
    end
end
