#include <QCoreApplication>

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    printf("hello xmake\n");
    return a.exec();
}
