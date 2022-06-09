#include <QtCore/QObject>
#include <QtQml/qqml.h>

class Foo: public QObject {
    Q_OBJECT
    Q_PROPERTY(int bar READ bar WRITE setBar NOTIFY barChanged)
    QML_NAMED_ELEMENT(Foo)

    public:
        explicit Foo(QObject *parent = nullptr);

        int bar() const noexcept;
        void setBar(int bar) noexcept;

    Q_SIGNALS:
        void barChanged(int bar);

    private:
        int m_bar;
};

QML_DECLARE_TYPE(Foo)
