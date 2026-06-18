import QtQuick
import QtQuick.Layouts

Item {
    id: popupRoot
    anchors.fill: parent
    visible: false // Controlled by clicking sidebar avatar badges

    // Properties fed from your AddUser/User retrieval metrics
    property string userName: ""
    property int currentPoints: 0
    property int lifetimePoints: 0
    property int outstandingCount: 0

    // Full screen overlay backing to blur/darken layout underneath
    Rectangle {
        anchors.fill: parent
        color: "#80000000" // Semitransparent dark backing

        TapHandler {
            onTapped: popupRoot.visible = false // Close modal when tapping outside
        }
    }

    // Centered White Glass-morphic Panel
    Rectangle {
        id: modalContent
        width: 600
        height: 450
        radius: 32
        color: "#FFFFFF"
        anchors.centerIn: parent

        // Trap inner taps so clicking inside the panel doesn't close it
        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 24

            Text {
                text: popupRoot.userName + "'s Stats"
                font.pixelSize: 32
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            // Stat Cards Row
            RowLayout {
                spacing: 20
                Layout.fillWidth: true

                // Current Points Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 140; radius: 24; color: "#F4F6F9"
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "Current Balance"; font.pixelSize: 16; color: "#6B7280"; /*anchors.horizontalCenter: parent*/ }
                        Text { text: String(popupRoot.currentPoints); font.pixelSize: 36; font.weight: Font.Bold; color: "#107C41"; /*anchors.horizontalCenter: parent*/ }
                    }
                }

                // Lifetime Points Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 140; radius: 24; color: "#F4F6F9"
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "Lifetime Earned"; font.pixelSize: 16; color: "#6B7280"; /*anchors.horizontalCenter: parent*/ }
                        Text { text: String(popupRoot.lifetimePoints); font.pixelSize: 36; font.weight: Font.Bold; color: "#1F2937"; /*anchors.horizontalCenter: parent*/ }
                    }
                }
            }

            // Status Badge Footer
            Rectangle {
                Layout.fillWidth: true
                height: 60; radius: 20
                color: popupRoot.outstandingCount > 0 ? "#FFF0F0" : "#E6F4EA"

                Text {
                    anchors.centerIn: parent
                    text: popupRoot.outstandingCount > 0
                        ? "⚠️ " + popupRoot.outstandingCount + " chores remaining today!"
                        : "🎉 All caught up for the day!"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: popupRoot.outstandingCount > 0 ? "#D93025" : "#137333"
                }
            }
        }
    }
}