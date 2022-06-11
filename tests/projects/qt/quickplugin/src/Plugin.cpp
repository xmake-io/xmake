#include "Plugin.h"

void qml_register_types_My_Plugin();

/////////////////////////////////////
/////////////////////////////////////
Plugin::Plugin(QObject *parent) : QQmlEngineExtensionPlugin { parent } {
    volatile auto registration = &qml_register_types_My_Plugin;
    Q_UNUSED(registration);
}
