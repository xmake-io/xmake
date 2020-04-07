#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

#if QT_VERSION >= 0x040400
QT_BEGIN_NAMESPACE
#endif

class MainWindowPrivate;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    MainWindowPrivate *d_ptr;
    Q_DECLARE_PRIVATE(MainWindow)
    Q_DISABLE_COPY(MainWindow)

    Q_PRIVATE_SLOT(d_func(), void mainWindow_slot())
};
#if QT_VERSION >= 0x040400
QT_END_NAMESPACE
#endif
#endif // MAINWINDOW_H
