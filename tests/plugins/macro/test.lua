function test_macro(t)
    -- we force to enable ccache to test it on ci
    os.exec("xmake f --mode=debug --policies=build.ccache:y -D -y")
    os.exec("xmake m -b")
    os.exec("xmake -r -a -D")
    os.exec("xmake m -e buildtest")
    os.exec("xmake m -l")
    os.exec("xmake m buildtest")
    os.exec("xmake m -d buildtest")
end

