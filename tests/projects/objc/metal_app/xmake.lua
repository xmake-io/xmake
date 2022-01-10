add_rules("mode.debug", "mode.release")

target("HelloTriangle")
    add_rules("xcode.application")
    add_includedirs("Renderer")
    add_frameworks("MetalKit")
    add_mflags("-fmodules")
    add_files("Renderer/*.m", "Renderer/*.metal")
    if is_plat("macosx") then
        add_files("Application/main.m")
        add_files("Application/AAPLViewController.m")
        add_files("Application/macOS/Info.plist")
        add_files("Application/macOS/Base.lproj/*.storyboard")
        add_defines("TARGET_MACOS")
        add_frameworks("AppKit")
    elseif is_plat("iphoneos") then
        add_files("Application/*.m")
        add_files("Application/iOS/Info.plist")
        add_files("Application/iOS/Base.lproj/*.storyboard")
        add_frameworks("UIKit")
        add_defines("TARGET_IOS")
    end
