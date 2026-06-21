import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 400; height: 500

    // 1. Make it modal
    modal: true
    focus: true

    Overlay.modal: Rectangle {
        color: focalisPopupBackground
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    background: Rectangle {
        color: "white"
        radius: 12
    }

    readonly property real centerX: (Overlay.overlay ? (Overlay.overlay.width - width) / 2 : 0)
    readonly property real centerY: (Overlay.overlay ? (Overlay.overlay.height - height) / 2 : 0)

    property real startX
    property real startY

    function showNear(targetItem, inData) {
        // Map from button
        var pos = targetItem.mapToItem(null, 0, 0)
        x = pos.x
        y = pos.y

        startX = pos.x
        startY = pos.y

        parseData(inData)
        open()
    }

    enter: Transition {
        ParallelAnimation {
            // Scale and Opacity
            NumberAnimation { property: "scale"; from: 0; to: 1; duration: 200; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }

            // Move to center
            NumberAnimation { property: "x"; to: root.centerX; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { property: "y"; to: root.centerY; duration: 200; easing.type: Easing.OutQuad }
        }
    }
    exit: Transition {
        ParallelAnimation {
            // Scale and Opacity
            NumberAnimation { property: "scale"; to: 0; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { property: "opacity"; to: 0; duration: 200 }

            //move back to initial position
            NumberAnimation { property: "x"; to: root.startX; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { property: "y"; to: root.startY; duration: 200; easing.type: Easing.OutQuad }
        }
    }


    // Data fields mapped directly from your JSON payload structure
    property string summary: ""
    property string user: ""
    property string username: ""
    property string userColor: "#64748B"
    property string timeString: ""
    property string location: ""
    property string description: ""
    property var attendees: [] // Array of string names

    function parseData(inData) {
        summary = inData.title || "";
        user = inData.assignedUser || "";
        username = userList[user].username || "";
        userColor = userList[user].color
        timeString = inData.timeString || "";
        location = inData.location || "";
        description = inData.description || "";
        attendees = inData.attendees || [];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: px40High
        spacing: px24High

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: root.userColor

                Text {
                    anchors.centerIn: parent
                    text: root.user !== "" ? root.username.charAt(0).toUpperCase() : ""
                    font.pixelSize: px24High
                    font.weight: Font.Bold
                    color: focalisWhite
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.leftMargin: 8 / 1920 * appWindow.width

                Text {
                    text: root.summary
                    font.pixelSize: px24High
                    color: focalisBlack
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Text {
                    text: root.timeString + " (" + root.username + ")"
                    font.pixelSize: px16High
                    font.weight: Font.Medium
                    color: focalisMidGray
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 20

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "DETAILS"; font.pixelSize: px13High; font.weight: Font.Bold; color: focalisMidGray }
                Text {
                    text: root.description;
                    font.pixelSize: 17;
                    color: flocalisDarkGray;
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.weight: Font.Medium
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: "LOCATION"; font.pixelSize: px13High; font.weight: Font.Bold; color: focalisMidGray }
                Text {
                    text: root.location
                    font.pixelSize: 18
                    color: flocalisDarkGray
                    font.weight: Font.Medium
                }
            }

            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true

                Text { text: "ATTENDEES"; font.pixelSize: px13High; font.weight: Font.Bold; color: focalisMidGray }

                // Horizontal row layout tracking pill list delegates
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: root.attendees
                        Rectangle {
                            height: 38
                            width: attendeeText.implicitWidth + 24
                            radius: 19
                            color: focalisLightGray
                            border.color: focalisMidGray

                            Text {
                                id: attendeeText
                                anchors.centerIn: parent
                                text: modelData.Name
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: focalisBlack
                            }
                        }
                    }
                }
            }
        }
    }

}
