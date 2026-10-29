import QtQuick

Rectangle {
    width: 100
    height: 40
    property alias text: label.text
    Text { id: label; anchors.centerIn: parent }
}
