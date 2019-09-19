#include "widgettest.h"
#include "ui_widgettest.h"

WidgetTest::WidgetTest(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::WidgetTest)
{
    ui->setupUi(this);
}

WidgetTest::~WidgetTest()
{
    delete ui;
}
