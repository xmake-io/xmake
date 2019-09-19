#include "mainwindowtest.h"
#include "ui_mainwindowtest.h"

MainWindowTest::MainWindowTest(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindowTest)
{
    ui->setupUi(this);
}

MainWindowTest::~MainWindowTest()
{
    delete ui;
}
