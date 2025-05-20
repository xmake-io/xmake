import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function _build(check_outdata)
    if check_outdata then
        local outdata
        if ci_is_running() then
            outdata = os.iorun("xmake -rvD")
        else
            outdata = os.iorun("xmake -rv")
        end
        if outdata then
            if outdata:find(check_outdata.str, 1, true) then
                raise(check_outdata.format_string, outdata)
            end
        end
    else
        if ci_is_running() then
            os.run("xmake -rvD")
        else
            os.run("xmake -r")
        end
    end
    local outdata = os.iorun("xmake")
    if outdata then
        if outdata:find("compiling", 1, true) or outdata:find("linking", 1, true) or outdata:find("generating", 1, true) then
            raise("Modules incremental compilation does not work\n%s", outdata)
        end
    end
end

function can_build()
    if is_subhost("windows") then
        return true
    elseif is_subhost("msys") then
        return true
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, GCC_MIN_VER) >= 0 then
            return true
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, CLANG_MIN_VER) >= 0 then
            return true
        end
    end
end

function build_tests(toolchain_name, opt)
    assert(opt and opt.version)
    local version
    if is_subhost("windows") then
        local msvc = toolchain.load("msvc")
        if not msvc or not msvc:check() then
            wprint("msvc not found, skipping tests")
            return
        end
        local vcvars = msvc:config("vcvars")
        if not vcvars or not vcvars.VCInstallDir or not vcvars.VCToolsVersion then
            wprint("msvc not found, skipping tests")
            return
        end
        version = vcvars.VCToolsVersion
    end
    if opt.compiler then
        local cc = find_tool(opt.compiler, {version = true})
        if not cc then
            wprint(opt.compiler .. " not found, skipping tests")
            return
        end
        version = cc.version
    end

    local compiler = toolchain_name == "msvc" and "cl" or opt.compiler
    if not version or not (semver.compare(version, opt.version) >= 0) then
        local version_str = compiler ..  " >= " .. opt.version .. (version and " (found " .. version .. ")" or "") .. " "
        wprint(version_str .. "not found, skipping tests")
        return
    end
    
    local policies = "--policies=build.c++.modules.std:" .. (opt.stdmodule and "y" or "n")
    policies = policies .. ",build.c++.modules.fallbackscanner:" .. (opt.fallbackscanner and "y" or "n")

    local platform = " "
    if opt.platform then
        platform = " -p "  .. opt.platform .. " "
    end

    local runtimes = " "
    if opt.runtimes then
        runtimes = " --runtimes=" .. opt.runtimes .. " "
        print("running with config: (toolchain: %s, compiler: %s, version: %s, runtimes: %s)", toolchain_name, compiler, version, opt.runtimes)
    else
        print("running with config: (toolchain: %s, compiler: %s, version: %s)", toolchain_name, compiler, version)
    end

    local flags = ""
    if opt.flags then
        flags = " " .. table.concat(opt.flags, " ")
    end

    os.exec("xmake clean -a")
    os.exec("xmake f" .. platform .. "--toolchain=" .. toolchain_name .. runtimes .. "-c --yes " .. policies .. flags)
    if opt.build then
        opt.build()
    else
        _build(opt.find_in_outdata)
    end
    if opt.after_build then
        opt.after_build(platform, toolchain_name, runtimes, policies, flags)
    end
end

function run_tests(clang_options, gcc_options, msvc_options)
    local clang_libcpp_options
    if clang_options then
        clang_libcpp_options = table.clone(clang_options)
        clang_libcpp_options.runtimes = "c++_shared"
    end
    if is_subhost("windows") then
        if clang_options then
            build_tests("llvm", clang_options)
            build_tests("clang", clang_options)
            if not clang_options.stdmodule then
                build_tests("llvm", clang_libcpp_options)
                build_tests("clang", clang_libcpp_options)
            else
                wprint("std modules tests skipped for Windows clang libc++ as it's not currently supported officially")
            end
        end
        if msvc_options then
            build_tests("msvc", msvc_options)
        end
    elseif is_subhost("macosx") then
        if clang_options then
            -- macOS doesn't ship clang-scan-deps currently
            if is_subhost("macosx") then
                -- check if normal clang is avalaible
                local regular_clang_available = false

                local outdata = os.iorun("clang --version")
                if outdata then
                    regular_clang_available = true
                    if outdata:find("Apple") then
                        regular_clang_available = false
                    end
                end
                if not regular_clang_available then
                    wprint("Appleclang isn't shipped with clang-scan-deps, disabling modules tests")
                    return
                end
            end
            build_tests("llvm", clang_options)
            build_tests("clang", clang_options)
        end
    elseif is_subhost("msys") then
        if clang_options then
            clang_options.platform = "mingw"
            clang_libcpp_options.platform = "mingw"
            build_tests("llvm", clang_options)
            build_tests("clang", clang_options)
            build_tests("llvm", clang_libcpp_options)
            build_tests("clang", clang_libcpp_options)
        end
        if gcc_options then
            gcc_options.platform = "mingw"
            build_tests("gcc", gcc_options)
        end
    elseif is_host("linux") then
        if clang_options then
            build_tests("llvm", clang_options)
            build_tests("clang", clang_options)
            build_tests("llvm", clang_libcpp_options)
            build_tests("clang", clang_libcpp_options)
        end
        if gcc_options then
            build_tests("gcc", gcc_options)
        end
    end
end

function main(_)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER}
    local msvc_options = {version = MSVC_MIN_VER}
    run_tests(clang_options, gcc_options, msvc_options)
end
