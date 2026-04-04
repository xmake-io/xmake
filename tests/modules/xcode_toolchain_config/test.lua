import("core.project.config")

local function _import_xcode_check()
    local rootdir = path.absolute(path.join(os.scriptdir(), "..", "..", "..", "xmake"))
    return import("toolchains.xcode.check", {rootdir = rootdir, anonymous = true})
end

function test_prefers_toolchain_local_xcode_config(t)
    if not is_host("macosx") then
        return t:skip("wrong host platform")
    end

    local check = _import_xcode_check()
    local old_xcode = config.get("xcode")
    config.set("xcode", "/tmp/global-xcode", {force = true})
    local toolchain = {
        config = function (_, name)
            if name == "xcode" then
                return "/tmp/local-xcode"
            end
        end
    }
    t:are_equal(check.get_xcode(toolchain), "/tmp/local-xcode")
    config.set("xcode", old_xcode, {force = true})
end

function test_falls_back_to_global_xcode_config(t)
    if not is_host("macosx") then
        return t:skip("wrong host platform")
    end

    local check = _import_xcode_check()
    local old_xcode = config.get("xcode")
    config.set("xcode", "/tmp/global-xcode", {force = true})
    local toolchain = {
        config = function () end
    }
    t:are_equal(check.get_xcode(toolchain), "/tmp/global-xcode")
    config.set("xcode", old_xcode, {force = true})
end
