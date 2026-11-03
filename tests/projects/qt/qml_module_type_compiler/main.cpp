#include <QGuiApplication>
#include <QQmlEngine>

// qmltc is enabled for this target, so the QML document is compiled into a C++
// class. Create the generated class directly instead of loading the QML at runtime.
#include "Main.qml.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlEngine engine;
    MyAppNs::Main window(&engine);
    return window.isVisible() ? 0 : -1;
}
