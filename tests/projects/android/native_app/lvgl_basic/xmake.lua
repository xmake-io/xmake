add_rules("mode.debug", "mode.release")

add_requires("lvgl 9.1.0")

target("lvgl_basic")
    set_kind("binary")
    set_languages("c99")
    add_files("src/main.c")
    add_syslinks("log", "android", "EGL", "GLESv2")
    add_packages("lvgl")
    
    -- define LV_CONF_INCLUDE_SIMPLE to include lv_conf.h
    add_defines("LV_CONF_INCLUDE_SIMPLE")
    
    add_rules("android.native_app", {
        android_sdk_version = "35",
        android_manifest = "android/AndroidManifest.xml",
        android_res = "android/res",
        keystore = "android/debug.jks",
        keystore_pass = "123456",
        package_name = "com.lvgl.basic",
        logcat_filters = {"lvgl_basic", "lvgl"}
    })
