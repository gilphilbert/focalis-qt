import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: filterSidebarRoot
    width: 300
    Layout.fillHeight: true
    color: "#F8FAFC"

    // Linked to reference the same state dictionary map on our primary calendar canvas
    property var calendarCanvasRef

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        Text {
            text: "Filter Family"
            font.pixelSize: 24
            //font.weight: Font.Bold
            color: "#0F172A"
        }

        ListView {
            id: userFilterList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            model: goUserBridgeModel // Shares your universal users data array

            delegate: Rectangle {
                width: userFilterList.width
                height: 72
                radius: 16

                // Dim background row frame opacity if hidden state index triggers true
                property bool isHidden: filterSidebarRoot.calendarCanvasRef ? !!filterSidebarRoot.calendarCanvasRef.hiddenUsers[model.name] : false
                color: isHidden ? "#F1F5F9" : "#FFFFFF"
                border.color: isHidden ? "transparent" : "#E2E8F0"

                TapHandler {
                    onTapped: {
                        if (!filterSidebarRoot.calendarCanvasRef) return;

                        // Mutate deep dictionary reference tree safely to trigger QML redraw notifications
                        let currentMap = filterSidebarRoot.calendarCanvasRef.hiddenUsers;
                        currentMap[model.name] = !currentMap[model.name];
                        filterSidebarRoot.calendarCanvasRef.hiddenUsers = currentMap;
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Mini check circle badge
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: isHidden ? "transparent" : "#107C41"
                        border.color: "#94A3B8"
                        border.width: isHidden ? 2 : 0
                        Text {
                            text: "✓"; color: "#FFFFFF";
                            //font.bold: true;
                            font.pixelSize: 14;
                            anchors.centerIn: parent;
                            visible: !isHidden
                        }
                    }

                    Text {
                        text: model.name
                        font.pixelSize: 18
                        //font.weight: isHidden ? Font.Normal : Font.Bold
                        color: isHidden ? "#94A3B8" : "#1E293B"
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}