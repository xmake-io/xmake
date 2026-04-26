import("utils.binary.rpath")

function main(t)
    if not is_host("linux") then
        return t:skip("wrong host platform")
    end

    local targetfile = path.join(os.scriptdir(), "bin", "demo")
    os.execv("chmod", {"+x", path.join(os.scriptdir(), "repro-gcc.sh")})
    t:build()

    local rpaths = rpath.list(targetfile) or {}
    t:require(table.contains(rpaths, path.join(os.scriptdir(), "lib")))
    t:require(os.iorunv("env", {"-u", "LD_LIBRARY_PATH", targetfile}):trim() == "foo=42")
end