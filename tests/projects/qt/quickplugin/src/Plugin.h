#include <QtCore/QObject>
#include <QtQml/QQmlEngineExtensionPlugin>

class Plugin: public QQmlEngineExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlEngineExtensionInterface_iid)

  public:
    explicit Plugin(QObject *parent = nullptr);
};
