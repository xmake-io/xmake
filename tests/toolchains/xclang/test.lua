import("core.tool.toolchain")
import("lib.detect.find_tool")

-- A renamed xmake supplies a working --version command without requiring xclang.
-- The clang marker is never executed by these discovery tests.
function _fixture(callback)
    local root = path.absolute(path.join("__tmp", "xclang-" .. hash.uuid4()))
    local files = {}
    local oldpath = os.getenv("PATH")
    local fixture = {}
    function fixture:write(name, content)
        local filename = path.join(root, name)
        io.writefile(filename, content or "")
        table.insert(files, filename)
        return filename
    end
    function fixture:sdk(name, target, manager)
        local bindir = path.join(root, name, "bin")
        os.mkdir(bindir)
        if manager ~= false then
            local filename = path.join(bindir, is_host("windows") and "xclang.exe" or "xclang")
            os.cp(os.programfile(), filename)
            table.insert(files, filename)
        end
        self:write(path.join(name, "bin", is_host("windows") and "clang.exe" or "clang"))
        self:write(path.join(name, "bin", target .. ".cfg"))
        return path.directory(bindir), bindir
    end
    local errors
    try {
        function () callback(fixture, root) end,
        catch { function (message) errors = message end }
    }
    os.setenv("PATH", oldpath)
    for _, filename in ipairs(files) do
        os.tryrm(filename)
    end
    if errors then
        raise(errors)
    end
end

function _load(opt)
    local instance, errors = toolchain.load("xclang", opt)
    assert(instance, errors)
    return instance
end

function test_target_config_selection(t)
    _fixture(function (fixture)
        -- Each SDK has exactly one target configuration. This catches accidental
        -- fallback to the host ABI, including native Windows builds using MinGW.
        local targets = {
            {"mingw", "x86_64", "x86_64-w64-windows-gnu"},
            {"mingw", "arm64", "aarch64-w64-windows-gnu"},
            {"linux", "x86_64", "x86_64-unknown-linux-gnu"},
            {"linux", "arm64", "aarch64-unknown-linux-gnu"},
            {"macosx", "x86_64", "x86_64-apple-darwin"},
            {"macosx", "arm64", "aarch64-apple-darwin"},
            {"windows", "x64", "x86_64-pc-windows-msvc"},
            {"windows", "arm64", "aarch64-pc-windows-msvc"},
            {"cross", "arm64", "aarch64-unknown-linux-gnu", "aarch64-unknown-linux-gnu-"},
            {"cross", "arm64", "aarch64-w64-windows-gnu", "aarch64-w64-mingw32-"},
            {"cross", "x86_64", "x86_64-unknown-linux-gnu", "x86_64-linux-gnu-"}
        }
        for i, target in ipairs(targets) do
            local sdkdir, bindir = fixture:sdk("target-" .. i, target[3])
            local instance = _load({plat = target[1], arch = target[2], sdkdir = sdkdir, cross = target[4]})
            t:require(instance:check())
            instance:load()
            for _, name in ipairs({"cxflags", "asflags", "ldflags", "shflags"}) do
                t:require(table.contains(table.wrap(instance:get(name)), "--target=" .. target[3]))
            end
            if target[1] == "mingw" then
                t:require(table.contains(table.wrap(instance:get("mrcflags")), "--target=" .. target[3]))
            end
            for _, name in ipairs({"cc", "cxx", "ld", "ar"}) do
                local program = instance:get("toolset." .. name)
                t:require(path.is_absolute(program))
                t:are_equal(path.translate(path.directory(program)):lower(), path.translate(bindir):lower())
            end
        end
    end)
end

function test_explicit_sdk_isolation(t)
    _fixture(function (fixture, root)
        local sdkdir, bindir = fixture:sdk("valid", "x86_64-w64-windows-gnu")
        os.setenv("PATH", path.joinenv(table.join({bindir}, path.splitenv(os.getenv("PATH")))))
        t:require(_load({plat = "mingw", arch = "x86_64"}):check())
        t:require_not(_load({plat = "mingw", arch = "x86_64", sdkdir = path.join(root, "missing")}):check())
        t:require_not(_load({plat = "mingw", arch = "x86_64", bindir = path.join(root, "missing-bin")}):check())
        local llvm = fixture:sdk("ordinary-llvm", "x86_64-w64-windows-gnu", false)
        t:require_not(_load({plat = "mingw", arch = "x86_64", sdkdir = llvm}):check())
        local wrongtarget = fixture:sdk("linux-only", "x86_64-unknown-linux-gnu")
        t:require_not(_load({plat = "mingw", arch = "x86_64", sdkdir = wrongtarget}):check())
        t:require(_load({plat = "mingw", arch = "x86_64", bindir = bindir}):check())
    end)
end

function _find_sdk()
    local sdkdir = os.getenv("XCLANG_SDK")
    if not sdkdir then
        local manager = find_tool("xclang", {force = true})
        if manager then
            sdkdir = path.directory(path.directory(manager.program))
        end
    end
    return sdkdir
end

function test_installed_distribution(t)
    local sdkdir = _find_sdk()
    if not sdkdir then
        return t:skip("Set XCLANG_SDK or put xclang on PATH to check a real distribution")
    end
    for _, target in ipairs({{"mingw", "x86_64"}, {"mingw", "arm64"}, {"linux", "x86_64"}, {"linux", "arm64"},
                             {"macosx", "x86_64"}, {"macosx", "arm64"}}) do
        local instance = _load({plat = target[1], arch = target[2], sdkdir = sdkdir})
        t:require(instance:check())
        instance:load()
        local cc, name = instance:tool("cc")
        t:are_equal(name, "clang")
        t:are_equal(path.translate(path.directory(cc)):lower(), path.translate(instance:bindir()):lower())
    end
end

function test_build(t)
    local sdkdir = _find_sdk()
    if not sdkdir then
        return t:skip("Set XCLANG_SDK or put xclang on PATH to build with a real distribution")
    end
    local projectdir = path.join(os.scriptdir(), "project")
    for _, target in ipairs({{"mingw", "x86_64"}, {"mingw", "arm64"}, {"linux", "x86_64"}, {"linux", "arm64"}}) do
        os.vrunv(os.programfile(), {"f", "-P", projectdir, "-c", "-y", "-p", target[1], "-a", target[2],
                                  "--toolchain=xclang", "--sdk=" .. sdkdir})
        os.vrunv(os.programfile(), {"-P", projectdir, "-r"})
        if (is_host("windows") and target[1] == "mingw") or (is_host("linux") and target[1] == "linux") then
            local hostarch = os.arch()
            if (target[2] == "x86_64" and (hostarch == "x86_64" or hostarch == "x64")) or
               (target[2] == "arm64" and (hostarch == "arm64" or hostarch == "aarch64")) then
                os.vrunv(os.programfile(), {"run", "-P", projectdir, "smoke"})
            end
        end
    end
end
