import QtQuick
import "utils.js" as Utils
import MyApp

Window {
    width: 320
    height: 200
    visible: true
    title: Utils.greeting("QML")
    MyButton { anchors.centerIn: parent; text: "sum=" + Utils.sum(1, 2) }
}
