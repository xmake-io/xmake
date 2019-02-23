#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlExtensionPlugin>
#include <QtPlugin>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    Q_IMPORT_PLUGIN(QtQuick2Plugin) 
//    Q_IMPORT_PLUGIN(QtQuick2WindowPlugin)

    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QtQuick2Plugin().instance())->registerTypes("QtQuick");
    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QtQuick2Plugin().instance()) ->initializeEngine( &engine, "QtQuick");

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
