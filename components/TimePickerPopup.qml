import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 320; height: 350
    modal: true
    focus: true
    padding: 20

    // Inputs from Main.qml
    property bool isPriorDay: false
    property int minHour: 9
    property int minMinute: 0
    property string minPeriod: "AM"
    property Item caller: null

    // Internal Picker State
    property int hour: 12
    property int minute: 0
    property string period: "AM"

    signal accepted(int hour, int minute, string period)

    // Calculate the minimum allowed time in absolute minutes from midnight (0 - 1439)
    readonly property int minAbsoluteMinutes: {
        if (isPriorDay) return 0; // No constraints if event started on a previous day

        var h = minHour
        if (minPeriod === "AM" && h === 12) h = 0
        else if (minPeriod === "PM" && h !== 12) h += 12

        return (h * 60) + minMinute
    }

    // Calculate the CURRENTLY SELECTED time in absolute minutes from midnight
    readonly property int currentAbsoluteMinutes: {
        var h = hour
        if (period === "AM" && h === 12) h = 0
        else if (period === "PM" && h !== 12) h += 12

        return (h * 60) + minute
    }

    // Helper to check if a specific combination is valid
    function isValidTime(h12, min, p) {
        if (isPriorDay) return true

        var h = h12
        if (p === "AM" && h === 12) h = 0
        else if (p === "PM" && h !== 12) h += 12

        return ((h * 60) + min) >= minAbsoluteMinutes
    }

    // Coordinates for center-screen animation
    readonly property real centerX: (Overlay.overlay ? (Overlay.overlay.width - width) / 2 : 0)
    readonly property real centerY: (Overlay.overlay ? (Overlay.overlay.height - height) / 2 : 0)

    function showNear(targetItem) {
        caller = targetItem
        var pos = targetItem.mapToItem(null, 0, 0)
        x = pos.x; y = pos.y
        open()
    }

    Overlay.modal: Rectangle { color: "#AA000000" }
    background: Rectangle { color: focalisWhite; radius: 12 }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "scale"; from: 0; to: 1; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { property: "x"; to: root.centerX; duration: 300; easing.type: Easing.OutQuad }
            NumberAnimation { property: "y"; to: root.centerY; duration: 300; easing.type: Easing.OutQuad }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 5

            // Hour Tumbler
            Tumbler {
                id: hourTumbler
                model: 12
                Layout.fillWidth: true
                delegate: Text {
                    // Check if this hour could be valid under the CURRENT minute/period selection
                    property bool isInvalid: !root.isValidTime(index + 1, root.minute, root.period)
                    text: (index + 1)
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: isInvalid ? 0.2 : (1.0 - Math.abs(Tumbler.displacement) * 0.4)
                    color: isInvalid ? "#FF3333" : (Math.abs(Tumbler.displacement) === 0 ? focalisBlack : "#888888")
                }
                onCurrentIndexChanged: hour = currentIndex + 1
            }

            // Minute Tumbler
            Tumbler {
                id: minTumbler
                model: 60
                Layout.fillWidth: true
                delegate: Text {
                    // Check if this minute is valid with the CURRENT hour/period selection
                    property bool isInvalid: !root.isValidTime(root.hour, index, root.period)
                    text: index.toString().padStart(2, '0')
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: isInvalid ? 0.2 : (1.0 - Math.abs(Tumbler.displacement) * 0.4)
                    color: isInvalid ? "#FF3333" : (Math.abs(Tumbler.displacement) === 0 ? focalisBlack : "#888888")
                }
                onCurrentIndexChanged: minute = currentIndex
            }

            // AM/PM Tumbler
            Tumbler {
                id: periodTumbler
                model: ["AM", "PM"]
                Layout.fillWidth: true
                delegate: Text {
                    // Check if this period is valid with the CURRENT hour/minute selection
                    property bool isInvalid: !root.isValidTime(root.hour, root.minute, modelData)
                    text: modelData
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: isInvalid ? 0.2 : (1.0 - Math.abs(Tumbler.displacement) * 0.4)
                    color: isInvalid ? "#FF3333" : (Math.abs(Tumbler.displacement) === 0 ? focalisBlack : "#888888")
                }
                onCurrentIndexChanged: period = (currentIndex === 0 ? "AM" : "PM")
            }
        }

        Button {
            text: "Set Time"
            Layout.fillWidth: true
            enabled: root.currentAbsoluteMinutes >= root.minAbsoluteMinutes
            onClicked: {
                root.accepted(hour, minute, period)
                root.close()
            }
        }
    }
}