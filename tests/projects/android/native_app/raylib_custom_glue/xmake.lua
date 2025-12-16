add_rules("mode.debug", "mode.release")

add_requires("raylib 5.5.0")

target("raydemo_custom_glue")
    set_kind("binary")
    set_languages("c++17")
    add_files("src/main.cpp", "src/android_native_app_glue.c")
    add_syslinks("log")
    add_packages("raylib")
    add_rules("android.native_app", {
        android_sdk_version = "35",
        android_manifest = "android/AndroidManifest.xml",
        android_res = "android/res",
        keystore = "android/debug.jks",
        keystore_pass = "123456",
        package_name = "com.raylib.custom_glue",
        native_app_glue = false,
        logcat_filters = {"raydemo_custom_glue", "raylib"}
    })
