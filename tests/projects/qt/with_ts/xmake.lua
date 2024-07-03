add_rules("mode.debug", "mode.release")

target("demo")
    add_rules("qt.widgetapp")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")
    add_files("src/mainwindow.h")
    add_files("src/demo_zh_CN.ts")
    add_files("src/demo_zh_TW.ts", {
        prefixdir = "translations"
    })