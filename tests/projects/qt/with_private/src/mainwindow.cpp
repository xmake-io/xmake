#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <private/qquicktext_p.h>
MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    QQuickText *text = new QQuickText();
    delete text;
}

MainWindow::~MainWindow()
{
    delete ui;
}
