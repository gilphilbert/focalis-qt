import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    modal: true
    focus: true
    width: Math.min(Overlay.overlay.width * 0.9, 450)
    height: Math.min(Overlay.overlay.height * 0.8, 550)
    anchors.centerIn: Overlay.overlay
    padding: 10

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.InOutQuad }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.InOutQuad }
    }

    property date initialDate: new Date()
    property date minDate: new Date(1900, 0, 1) // Default to long ago

    // The signal now only passes a single date
    signal accepted(date selectedDate)

    background: Rectangle { color: "#FFFFFF"; radius: 16 }

    // --- Navigation Overlay (Seamless Wheel Picker) ---
    Rectangle {
        id: navOverlay
        anchors.fill: parent
        z: 10
        color: "#FFFFFF"
        visible: opacity > 0
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            Row {
                Layout.alignment: Qt.AlignHCenter
                Tumbler {
                    id: monthTumbler
                    model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                    Component.onCompleted: currentIndex = new Date().getMonth()
                }
                Tumbler {
                    id: yearTumbler
                    model: 50 // 2000-2050
                    Component.onCompleted: currentIndex = new Date().getFullYear() - 2000
                }
            }
            Button {
                text: "Confirm"
                Layout.fillWidth: true
                onClicked: {
                    grid.month = monthTumbler.currentIndex
                    grid.year = 2000 + yearTumbler.currentIndex
                    navOverlay.opacity = 0
                }
            }
        }
    }

    // --- Main Layout ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            text: Qt.formatDate(new Date(grid.year, grid.month), "MMMM yyyy")
            font.pixelSize: 20
            onClicked: navOverlay.opacity = 1
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            //month: new Date().getMonth()
            //year: new Date().getFullYear()
            month: initialDate.getMonth()
            year: initialDate.getFullYear()

            delegate: Rectangle {
                id: dayCell
                required property date date
                required property int day
                property bool isToday: date.toDateString() === new Date().toDateString()
                readonly property bool isValid: date >= minDate

                width: grid.width / 7
                height: grid.height / 6

                color: isToday ? "#e0e0e0" : "transparent"
                radius: 8
                border.color: isToday ? "#3daee9" : "transparent"
                border.width: isToday ? 2 : 0

                Text {
                    text: day
                    anchors.centerIn: parent
                    font.pixelSize: 18
                    font.bold: isToday
                }

                // --- The Pulse Animation ---
                SequentialAnimation {
                    id: pulseAnim
                    ScaleAnimator { target: dayCell; from: 1; to: 0.85; duration: 100; easing.type: Easing.OutQuad }
                    ScaleAnimator { target: dayCell; from: 0.85; to: 1; duration: 100; easing.type: Easing.OutQuad }
                    onFinished: {
                        root.accepted(date)
                        root.close()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: isValid // Disable clicking on invalid days
                    onClicked: {
                        // Apply the visual pulse only if valid
                        if (isValid) pulseAnim.start()
                    }
                }
            }
        }
    }
}