-- main entry
function main(argv)

    -- generic?
    os.exec("$(xmake) m -b")
    os.exec("$(xmake) f -c")
    os.exec("$(xmake)")
    if os.host() ~= "windows" then
        os.exec("sudo $(xmake) install")
        os.exec("sudo $(xmake) uninstall")
    end
    os.exec("$(xmake) p")
    os.exec("$(xmake) c")
    os.exec("$(xmake) f -m release")
    os.exec("$(xmake) -r -a -v --backtrace")
    if os.host() ~= "windows" then
        os.exec("sudo $(xmake) install --all -v --backtrace")
        os.exec("sudo $(xmake) uninstall -v --backtrace")
    end
    os.exec("$(xmake) f --mode=debug --verbose --backtrace")
    os.exec("$(xmake) --rebuild --all --verbose --backtrace")
    if os.host() ~= "windows" then
        os.exec("$(xmake) install -o /tmp -a --verbose --backtrace")
        os.exec("$(xmake) uninstall --installdir=/tmp --verbose --backtrace")
    end
    os.exec("$(xmake) p --verbose --backtrace")
    os.exec("$(xmake) c --verbose --backtrace")
    os.exec("$(xmake) m -e buildtest")
    os.exec("$(xmake) m -l")
    os.exec("$(xmake) f --cc=gcc --cxx=g++")
    os.exec("$(xmake) m buildtest")
    os.exec("$(xmake) f --cc=clang --cxx=clang++ --ld=clang++ --verbose --backtrace")
    os.exec("$(xmake) m buildtest")
    os.exec("$(xmake) m -d buildtest")

    -- test iphoneos?
    if argv and argv.iphoneos then
        if os.host() == "macosx" then
            os.exec("$(xmake) m package -p iphoneos")
        end
    end
end
