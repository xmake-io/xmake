-- imports
import("privilege.sudo")

local test_build = {}

function test_build:build(argv)

    -- check global config
    os.exec("xmake g -c")

    -- generic?
    os.exec("xmake f -c")
    os.exec("xmake")
    os.exec("xmake p -D")
    if os.host() ~= "windows" then
        os.exec("xmake install -o /tmp -a -D")
        os.exec("xmake uninstall --installdir=/tmp -D")
    end
    os.exec("xmake c -D")
    os.exec("xmake f --mode=debug -D")
    os.exec("xmake m -b")
    os.exec("xmake -r -a -D")
    os.exec("xmake m -e buildtest")
    os.exec("xmake m -l")
    os.exec("xmake m buildtest")
    if sudo.has() then
        sudo.exec("xmake install --all -D")
        sudo.exec("xmake uninstall -D")
    end
    os.exec("xmake m -d buildtest")

    -- test iphoneos?
    if argv and argv.iphoneos then
        if os.host() == "macosx" then
            os.exec("xmake m package -p iphoneos")
        end
    end
end

function main()
    return test_build
end
