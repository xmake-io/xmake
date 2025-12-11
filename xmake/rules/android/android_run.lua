function main(target, apk_output_path, package_name, activity_name)
    import("core.tool.toolchain")
    local toolchain_ndk = toolchain.load("ndk", {plat = target:plat(), arch = target:arch()})
    local android_sdkdir = path.translate(assert(toolchain_ndk:config("android_sdk"), "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))
    local adb = path.join(android_sdkdir, "platform-tools", "adb" .. (is_host("windows") and ".exe" or ""))

    local outputpath = path.join("build", "android", "output")
    local outputtemppath = path.join(outputpath, "temp")
    assert(os.exists(outputtemppath))

    local final_output_path = apk_output_path or outputtemppath
    local final_apk = path.join(final_output_path, target:basename() .. ".apk")
    assert(os.exists(final_apk))

    local install_argv = {
        "install", final_apk,
    }

    cprint("{green}[Installing apk] ...")
    os.vrunv(adb, install_argv)

    local run_argv = {
        "shell",
        "am",
        "start", "-n",
        package_name .. "/" .. activity_name
    }

    cprint("{green}[Run apk] ...")
    os.vrunv(adb, run_argv)
end
