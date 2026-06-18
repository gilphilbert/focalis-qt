import QtQuick
import QtQuick.Controls
import QtQuick.Effects // For modern smooth shadows and blurs

Item {
    id: root
    width: 280
    height: 180

    // Properties mapped straight from your Clover ChoreSummary struct
    property string choreId: ""
    property string title: ""
    property string assignedTo: ""
    property int points: 0
    property string status: "pending"

    signal choreToggled(string id)

    // Sleek background card container
    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 24
        color: root.status === "completed" ? "#107C41" : "#FFFFFF"
        border.color: root.status === "completed" ? "transparent" : "#E0E6ED"
        border.width: 2

        // Smooth state transition animation
        Behavior on color { ColorAnimation { duration: 250 } }

        // Massive Touch Target MouseArea/TapHandler
        TapHandler {
            onTapped: {
                // Emit signal to Go backend to invoke MarkChoreAsDone
                root.choreToggled(root.choreId)
            }
        }

        // Layout inner components
        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Text {
                text: root.title
                font.pixelSize: 22
                //font.weight: Font.Bold
                color: root.status === "completed" ? "#FFFFFF" : "#1F2937"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                width: parent.width
                anchors.bottom: parent.bottom

                // Point pill marker
                Rectangle {
                    width: 80; height: 36; radius: 18
                    color: root.status === "completed" ? "rgba(255,255,255,0.2)" : "#FFF8E7"

                    Text {
                        anchors.centerIn: parent
                        text: "+" + root.points + " pts"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: root.status === "completed" ? "#FFFFFF" : "#FFB900"
                    }
                }
            }
        }
    }
}