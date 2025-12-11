function main(target, android_sdk_version, android_manifest, android_res, android_assets, attachedjar, keystore,
    keystore_pass, apk_output_path)
    local outputpath = path.join("build", "android", "output")
    if os.exists(outputpath) then
        os.rmdir(outputpath)
    end
    local outputtemppath = path.join(outputpath, "temp")
    os.mkdir(outputtemppath)
    local libpath = path.join(outputpath, "lib")
    os.mkdir(libpath)
    local libarchpath = path.join(libpath, target:arch())
    os.mkdir(libarchpath)
    os.cp(path.join(target:installdir(), "lib", "*.so"), libarchpath)

    -- rename to libmain.so
    local target_filename = target:filename()
    local source_lib = path.join(libarchpath, target_filename)
    local dest_lib = path.join(libarchpath, "libmain.so")
    if os.exists(source_lib) then
        os.mv(source_lib, dest_lib)
    else
        os.raise("can't find source lib: " .. source_lib)
    end

    import("core.tool.toolchain")

    local toolchain_ndk = toolchain.load("ndk", {
        plat = target:plat(),
        arch = target:arch()
    })

    -- get ndk
    local ndk = path.translate(assert(toolchain_ndk:config("ndk"), "cannot get NDK!"))

    -- get android sdk directory
    local android_sdkdir = path.translate(assert(toolchain_ndk:config("android_sdk"),
        "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))

    -- get android build-tools version
    local android_build_toolver = assert(toolchain_ndk:config("build_toolver"),
        "please run `xmake f --build_toolver=xxx` to set the android build-tools version!")

    local androidjar = path.join(android_sdkdir, "platforms", string.format("android-%s", android_sdk_version),
        "android.jar")

    local aapt = path.join(android_sdkdir, "build-tools", android_build_toolver,
        "aapt" .. (is_host("windows") and ".exe" or ""))

    --------------------------------------- pack resources 
    local resonly_apk = path.join(outputtemppath, "res_only.apk")
    local aapt_argv = {"package", "-f", "-M", android_manifest, "-I", androidjar, "-F", resonly_apk}

    if android_res ~= nil and os.exists(android_res) then
        table.insert(aapt_argv, "-S")
        table.insert(aapt_argv, android_res)
    end

    if android_assets ~= nil and os.exists(android_assets) and os.emptydir(android_assets) == false then
        table.insert(aapt_argv, "-A")
        table.insert(aapt_argv, android_assets)
    end

    cprint("${green}[Android][Packing resources]${white} Save to " .. resonly_apk .. "...")
    os.vrunv(aapt, aapt_argv)

    --------------------------------------- pack libs 
    local curdir = os.cd(outputpath)
    os.vrunv(aapt, {"add", "temp/res_only.apk", path.join("lib", target:arch(), "libmain.so")})
    cprint("${green}[Android][Packing library]${white} Adding lib/" .. target:arch() .. "/libmain.so to res_only.apk...")
    os.cd(curdir)

    --------------------------------------- align apk
    local aligned_apk = path.join(outputtemppath, "unsigned.apk")
    local zipalign = path.join(android_sdkdir, "build-tools", android_build_toolver,
        "zipalign" .. (is_host("windows") and ".exe" or ""))
    local zipalign_argv = {"-f", "4", resonly_apk, aligned_apk}

    cprint("${green}[Android][Align apk]${white} Save to " .. aligned_apk .. "...")
    os.vrunv(zipalign, zipalign_argv)

    --------------------------------------- sign apk
    local final_apk = path.join(apk_output_path, target:basename() .. ".apk")
    local apksigner = path.join(android_sdkdir, "build-tools", android_build_toolver,
        "apksigner" .. (is_host("windows") and ".bat" or ""))
    local apksigner_argv = {"sign", "--ks", keystore, "--ks-pass", string.format("pass:%s", keystore_pass), "--out",
                            final_apk, "--in", aligned_apk}

    cprint("${green}[Android][Signing apk]${white} Save to " .. final_apk .. "...")
    os.vrunv(apksigner, apksigner_argv)
    
end
