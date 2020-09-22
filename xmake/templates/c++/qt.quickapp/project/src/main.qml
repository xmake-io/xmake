import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.2

Window {
    id: root
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")
    Button {
        text: "Ok"
        onClicked: {
            root.color = Qt.rgba(Math.random(), Math.random(), Math.random(), 1);
        }
    }
}

