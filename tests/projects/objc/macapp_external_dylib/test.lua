function _build_external_dylib()
    local arch = os.arch()
    local sdkdir = os.iorunv("xcrun", {"--sdk", "macosx", "--show-sdk-path"}):trim()
    os.execv("xcrun", {
        "--sdk", "macosx", "clang",
        "-dynamiclib",
        "-target", arch .. "-apple-macos",
        "-isysroot", sdkdir,
        "-install_name", "@rpath/libextfoo.dylib",
        "-o", "ext/libextfoo.dylib",
        "ext/extfoo.c"
    })
end

function main(t)
    if not is_host("macosx") then
        return t:skip("wrong host platform")
    end

    local homedir = path.absolute("home")
    os.setenv("HOME", homedir)
    os.mkdir(homedir)
    os.mkdir(path.join(homedir, ".xmake"))

    _build_external_dylib()
    local arch = os.arch()

    local xmake = path.absolute(path.join(os.projectdir(), "build", "xmake"))
    local xmake_program_dir = path.absolute(path.join(os.projectdir(), "xmake"))
    os.setenv("XMAKE_PROGRAM_FILE", xmake)
    os.setenv("XMAKE_PROGRAM_DIR", xmake_program_dir)

    os.execv(xmake, {"f", "-p", "macosx", "-a", arch, "-c"})
    os.execv(xmake, {"-vD"})

    local appdir = path.join("build", "macosx", arch, "release", "demo.app", "Contents", "Frameworks")
    local dylibfile = path.join(appdir, "libextfoo.dylib")
    if not os.isfile(dylibfile) then
        raise("missing external dylib in macOS app bundle: %s", dylibfile)
    end
end
