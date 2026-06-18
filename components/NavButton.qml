import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

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
                visible: false
            }

            ColorOverlay {
                x: btnImg.x
                y: btnImg.y
                Layout.preferredHeight: btnImg.height
                Layout.preferredWidth: btnImg.width
                source: btnImg
                color: btnRoot.isActive ? focalisWhite : focalisSkyBlue
                visible: icon != ""
            }
        }
    }
}