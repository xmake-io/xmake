#include "mainwindow.h"
#include <QApplication>
#include <QDebug>
#include <zlib.h>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    qDebug() << "zlib version:" << zlibVersion();
    MainWindow w;
    w.show();
    return a.exec();
}

