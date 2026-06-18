import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: popupRoot
    anchors.fill: parent
    visible: false // Toggled open via clicking a calendar event card

    TapHandler {}

    // Data fields mapped directly from your JSON payload structure
    property string summary: ""
    property string user: ""
    property string username: ""
    property string userColor: "#64748B"
    property string timeString: ""
    property string location: ""
    property string description: ""
    property var attendees: [] // Array of string names

    // Open utility function to easily populate data and show the modal
    function openEvent(eventData) {
        summary = eventData.title || "";
        user = eventData.assignedUser || "";
        username = userList[popupRoot.user].username || "";
        userColor = userList[user].color
        timeString = eventData.timeString || "";
        location = eventData.location || "";
        description = eventData.description || "";
        attendees = eventData.attendees || [];
        visible = true;
    }

    // Semi-transparent dark background mask
    Rectangle {
        anchors.fill: parent
        color: focalisPopupBackground

        TapHandler {
            onTapped: popupRoot.visible = false // Dismiss when tapping the background mask
        }
    }

    // Main Visual Card Frame
    Rectangle {
        id: modalContainer
        width: 650 / 1920 * appWindow.width
        height: 550 / 1080 * appWindow.height
        radius: px32High
        color: focalisWhite
        anchors.centerIn: parent

        // Trap touch events inside the card so they don't accidentally close the modal
        TapHandler {}

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
                    color: popupRoot.userColor

                    Text {
                        anchors.centerIn: parent
                        text: popupRoot.user != "" ? popupRoot.username.charAt(0).toUpperCase() : ""
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
                        text: popupRoot.summary
                        font.pixelSize: px24High
                        color: focalisBlack
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    Text {
                        text: popupRoot.timeString + " (" + popupRoot.username + ")"
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
                        text: popupRoot.description;
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
                        text: popupRoot.location
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
                            model: popupRoot.attendees
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

            Button {
                id: closeBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.topMargin: 12

                background: Rectangle {
                    radius: 18
                    color: closeBtn.down ? "#E2E8F0" : "#F1F5F9"

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        //font.pixelSize: 18
                        //color: focalisBlack
                        font.pixelSize: px18High
                        font.weight: Font.Bold
                        color: focalisMidGray
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onClicked: popupRoot.visible = false
            }
        }
    }
}