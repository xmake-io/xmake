import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")

function _build()
    local ci = (os.getenv("CI") or os.getenv("GITHUB_ACTIONS") or ""):lower()
    if ci == "true" then
        os.exec("xmake -rvD")
    else
        os.exec("xmake -r")
    end
end

function main(t)
    if is_subhost("windows") then
        local msvc = toolchain.load("msvc")
        if msvc and msvc:check() then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir and vcvars.VCToolsVersion and semver.compare(vcvars.VCToolsVersion, "14.35") then
                local stdmodulesdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "modules")
                if os.isdir(stdmodulesdir) then
                    os.exec("xmake f -c")
                    _build()
                end
            end
        end
    elseif is_host("linux") then -- or is_host("macos") then
        -- gcc don't support std modules atm
        -- local gcc = find_tool("gcc", {version = true})
        -- if is_host("linux") and gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            -- os.exec("xmake f -c")
            -- _build()
        -- end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            -- clang don't support libstdc++ std modules atm
            -- os.exec("xmake clean -a")
            -- os.exec("xmake f --toolchain=clang -c")
            -- _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --cxxflags=\"-stdlib=libc++\" -c")
            _build()
        end
    end
end
