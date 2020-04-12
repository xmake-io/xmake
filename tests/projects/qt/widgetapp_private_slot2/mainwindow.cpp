#include "mainwindow.h"
#include <QDebug>

class MainWindowPrivate:public QObject
{
    Q_OBJECT
public:
    MainWindow *q_ptr;
    Q_DECLARE_PUBLIC(MainWindow)
public:
    MainWindowPrivate(){}
    void mainWindow_slot(){qDebug()<<"mainWindow_slot";}
private:
     Q_PRIVATE_SLOT(q_ptr, void test())
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

void MainWindow::test()
{

}

#include "moc_mainwindow.cpp"
#include "mainwindow.moc"
