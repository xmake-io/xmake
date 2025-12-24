import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = is_subhost("windows") and "19" or "17"
CLANG_CL_MIN_VER = "19"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function _build(check_outdata)
    print("Building ...")
    local flags = ""
    if ci_is_running() then
        flags = "-vD"
    end
    if check_outdata then
        local outdata
        outdata = os.iorun("xmake -r " ..  flags)
        if outdata then
            if outdata:find(check_outdata.str, 1, true) then
                raise(check_outdata.format_string .. "\n%s", outdata)
            end
        end
    else
        os.exec("xmake -r " .. flags)
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
    print("Building test", toolchain_name, opt)
    local version
    if is_subhost("windows") then
        local msvc = toolchain.load("msvc")
        if not msvc or not msvc:check() then
            print("msvc not found, skipping tests")
            return
        end
        local vcvars = msvc:config("vcvars")
        if not vcvars or not vcvars.VCInstallDir or not vcvars.VCToolsVersion then
            print("msvc not found, skipping tests")
            return
        end
        version = vcvars.VCToolsVersion
    end
    if opt.compiler then
        local cc = find_tool(opt.compiler, {version = true})
        print("find tool", cc)
        if not cc then
            print(opt.compiler .. " not found, skipping tests")
            return
        end
        version = cc.version
    end

    local compiler = toolchain_name == "msvc" and "cl" or opt.compiler
    if not version or not (semver.compare(version, opt.version) >= 0) then
        local version_str = compiler ..  " >= " .. opt.version .. (version and " (found " .. version .. ")" or "") .. " "
        print(version_str .. "not found, skipping tests")
        return
    end

    local two_phases = (opt.two_phases == nil or opt.two_phases == true)
    local policies = "--policies=build.c++.modules.std:" .. (opt.stdmodule and "y" or "n")
    policies = policies .. ",build.c++.modules.fallbackscanner:" .. (opt.fallbackscanner and "y" or "n")
    policies = policies .. ",build.c++.modules.two_phases:" .. (two_phases and "y" or "n")

    local platform = " "
    if opt.platform then
        platform = " -p "  .. opt.platform .. " "
    end

    local runtimes = " "
    if opt.runtimes then
        runtimes = " --runtimes=" .. opt.runtimes .. " "
    end
    print("running with config: (toolchain: %s, compiler: %s, version: %s, runtimes: %s, stdmodule: %s, fallback scanner: %s, two phases: %s)",
        toolchain_name, compiler, version, opt.runtimes or "default", opt.stdmodule or false, opt.fallbackscanner or false, two_phases)

    local flags = ""
    if opt.flags then
        flags = " " .. table.concat(opt.flags, " ")
    end
    if ci_is_running() then
        flags = flags .. " -vD"
    end

    print("Running config ..", opt)
    os.exec("xmake clean -a")
    os.exec("xmake f" .. platform .. "--toolchain=" .. toolchain_name .. runtimes .. "-c --yes " .. policies .. flags)
    if opt.build then
        opt.build()
    else
        _build(opt.check_outdata)
    end
    if opt.after_build then
        opt.after_build(platform, toolchain_name, runtimes, policies, flags)
    end
end

function run_tests(clang_options, gcc_options, msvc_options)
    print("running tests")
    local clang_libcpp_options
    if clang_options then
        clang_libcpp_options = table.clone(clang_options)
        clang_libcpp_options.runtimes = "c++_shared"
    end
    if is_subhost("windows") then
        if clang_options then
            if not clang_options.disable_clang_cl then
                local clang_cl_options = table.clone(clang_options)
                clang_cl_options.compiler = "clang-cl"
                clang_cl_options.version = CLANG_CL_MIN_VER
                print("Building clang-cl", clang_cl_options)
                build_tests("clang-cl", clang_cl_options)
                --build_tests("clang-cl", table.join(clang_options, {two_phases = false}))
            end
        end
    end
end

function main(_)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER}
    local msvc_options = {version = MSVC_MIN_VER}
    run_tests(clang_options, gcc_options, msvc_options)
end
