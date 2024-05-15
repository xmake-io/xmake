#include "mainwindow.h"
#include <QApplication>
#include <QLocale>
#include <QTranslator>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QTranslator translator;
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString& locale : uiLanguages) {
        const QString baseName = "demo_" + QLocale(locale).name();
        if (translator.load(baseName + ".qm")) {
            a.installTranslator(&translator);
            break;
        }
    }
    MainWindow w;
    w.show();

    return a.exec();
}
