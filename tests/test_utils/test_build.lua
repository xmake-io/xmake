local test_build = {}

function test_build:build(argv)
    os.exec("xmake f -c -D -y")
    os.exec("xmake")
    os.rm("build")
    --os.exec("xmake f -c -D -y --policies=compatibility.version:3.0")
    os.exec("xmake f -c -D -y --policies=compatibility.version=3.0") -- FIXME
    os.exec("xmake -r")
end

function main()
    return test_build
end
