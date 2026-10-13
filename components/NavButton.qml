import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: btnRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 92

    property string iconText: ""
    property string icon: ""
    property string labelText: "Menu"
    property bool isActive: false

    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        radius: 20
        color: btnRoot.isActive ? focalisSkyBlue : "transparent"

        TapHandler {
            onTapped: btnRoot.clicked()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: btnRoot.iconText
                font.pixelSize: 28//32
                Layout.alignment: Qt.AlignHCenter
                visible: iconText != ""
            }

            Image {
                id: btnImg
                height: 32
                width: 32
                sourceSize.height: 32
                sourceSize.width: 32
                source: icon
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: btnRoot.isActive ? focalisWhite : focalisSkyBlue
                }
            }
        }
    }
}