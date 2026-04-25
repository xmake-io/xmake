import("utils.binary.rpath")

function main(t)
    if not is_host("linux") then
        return t:skip("wrong host platform")
    end

    os.execv("chmod", {"+x", "repro-gcc.sh"})
    t:build()

    local rpaths = rpath.list("bin/demo") or {}
    t:require(table.contains(rpaths, path.join(os.scriptdir(), "lib")))
    t:require(os.iorun("env -u LD_LIBRARY_PATH ./bin/demo"):trim() == "foo=42")
end