rule("android.cpp")
    if is_plat("android") then
        on_load(function (target)
            import("core.tool.toolchain")
            local toolchain_ndk = toolchain.load("ndk", {plat = target:plat(), arch = target:arch()})
            if not toolchain_ndk then
                raise("NDK toolchain not found! Please configure NDK properly.")
            end
            
            local ndk_root = toolchain_ndk:config("ndk")
            if not ndk_root then
                raise("NDK path not set! Please set NDK path properly.")
            end
            
            local native_app_glue_path = path.join(ndk_root, "sources", "android", "native_app_glue")
            
            -- Add glue file and jni interface file to target
            local conf = target:extraconf("rules", "android.cpp") 
            local jni_inferface = conf.jni_interface
            target:add("files", jni_inferface)
            target:add("files", path.join(native_app_glue_path, "android_native_app_glue.c"))
            target:add("includedirs", native_app_glue_path)
        end)

        after_install(function (target)
            local conf = target:extraconf("rules", "android.cpp") 
            local android_sdk_version = conf.android_sdk_version
            local android_manifest = conf.android_manifest
            local android_res = conf.android_res
            local android_assets = conf.android_assets
            local keystore = conf.keystore
            local keystore_pass = conf.keystore_pass or "123456"
            local apk_output_path = conf.apk_output_path or "."
            local attachedjar = conf.attachedjar

            assert(android_sdk_version, "android sdk version not set")
            assert(android_manifest, "android manifest not set")

            import("android_install")(target, android_sdk_version, android_manifest, android_res, 
                    android_assets, attachedjar, keystore, keystore_pass, apk_output_path)
        end)

        on_run(function (target)
            local conf = target:extraconf("rules", "android.cpp") 
            local apk_output_path = conf.apk_output_path or "."
            local package_name = conf.package_name
            local activity_name = conf.activity_name

            assert(package_name, "package name not set")
            assert(activity_name, "activity name not set")

            import("android_run")(target, apk_output_path, package_name, activity_name)
        end)
    end
