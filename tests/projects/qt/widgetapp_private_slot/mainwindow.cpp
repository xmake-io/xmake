#include "mainwindow.h"
#include <QDebug>

class MainWindowPrivate
{
    MainWindow *q_ptr;
    Q_DECLARE_PUBLIC(MainWindow)
public:
    MainWindowPrivate(){}
    void mainWindow_slot(){qDebug()<<"mainWindow_slot";}
};

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent)
{
    d_ptr = new MainWindowPrivate;
    d_ptr->q_ptr = this;
}

MainWindow::~MainWindow()
{

}

#include "moc_mainwindow.cpp"
