import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: sidebarRoot
    width: 340
    Layout.fillHeight: true
    color: "blue" // Soft Slate background tint

    // Signal to notify the main window to open the stats popup
    signal userSelected(string name, int currentPoints, int lifetimePoints, int outstandingCount)

    // Bridge property to bind your Go user data model
    property alias userModel: userListView.model

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // Section Title
        Text {
            text: "Family Profiles"
            font.pixelSize: 24
            //font.weight: Font.Bold
            color: "#0F172A"
            Layout.fillWidth: true
            Layout.bottomMargin: 10
        }

        // Scrollable List of users
        ListView {
            id: userListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            clip: true

            delegate: Rectangle {
                width: userListView.width
                height: 100
                radius: 20
                color: mouseArea.containsPress ? "#E2E8F0" : "#FFFFFF"
                border.color: model.outstandingCount > 0 ? "#FFB900" : "#E2E8F0"
                border.width: model.outstandingCount > 0 ? 2 : 1

                // Smooth hover/press transitions
                Behavior on color { ColorAnimation { duration: 100 } }

                TapHandler {
                    id: mouseArea
                    onTapped: {
                        // Forward user stats up to the parent window container
                        sidebarRoot.userSelected(
                            model.name,
                            model.currentPoints,
                            model.lifetimePoints,
                            model.outstandingCount
                        )
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    // Circular Avatar Placeholder
                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: model.outstandingCount > 0 ? "#FFF8E7" : "#E6F4EA"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: model.name.charAt(0).toUpperCase()
                            font.pixelSize: 28
                            //font.weight: Font.Bold
                            color: model.outstandingCount > 0 ? "#B7791F" : "#137333"
                        }
                    }

                    // User Info
                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        Text {
                            text: model.name
                            font.pixelSize: 20
                            //font.weight: Font.Bold
                            color: "#1E293B"
                        }

                        Text {
                            text: model.currentPoints + " pts"
                            font.pixelSize: 16
                            color: "#64748B"
                        }
                    }

                    // Streak Indicator (Right Side Badge)
                        Rectangle {
                            width: 60
                            height: 32
                            radius: 16
                            color: "#FFEDD5"
                            Layout.alignment: Qt.AlignVCenter
                            visible: model.streakDays > 0

                            Text {
                                anchors.centerIn: parent
                                text: "🔥 " + model.streakDays
                                font.pixelSize: 14
                                //font.weight: Font.Bold
                                color: "#EA580C"
                            }
                        }
                }
            }
        }
    }
}