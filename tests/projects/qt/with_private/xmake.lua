add_rules("mode.debug", "mode.release")

target("demo")
    add_rules("qt.widgetapp")
    add_frameworks("QtCore", "QtGui", "QtWidgets", "QtQuick", "QtQuickPrivate", "QtQml", "QtQmlPrivate", "QtCorePrivate", "QtGuiPrivate")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")
    add_files("src/mainwindow.h")


