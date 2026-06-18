import QtQuick
import QtQuick.Layouts
import QtQuick.Controls


Rectangle {
    id: toastRoot

    width: 350 / 1920 * appWindow.width
    height: 85 / 1080 * appWindow.height
    radius: 12 / 1080 * appWindow.height
    color: toastType == "success" ? focalisGreen : toastType == "error" ? focalisRed : toastType == "warning" ? focalisYellow : focalisSkyBlue
    y: 10 / 1080 * appWindow.height
    x: appWindow.width

    // Properties fed from your AddUser/User retrieval metrics
    property string toastMessage: ""
    property string toastType: ""
    property int timeout: 10

    function show(type, message) {
        toastType = type
        toastMessage = message
        toastRoot.x = appWindow.width - (width + y)
        toastTimer.start()
    }

    Behavior on x {
        NumberAnimation {
            easing.type: Easing.InOutQuad
            //easing.amplitude: 3.0
            //easing.period: 2.0
            duration: 400
        }
    }

    Timer {
        id: toastTimer
        running: false
        interval: 10000
        repeat: false
        onTriggered: toastRoot.x = appWindow.width
    }

    // Trap inner taps so clicking inside the panel doesn't close it
    TapHandler {}

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: toastType == "success" ? "Success!" : toastType == "error" ? "Error" : toastType == "warning" ? "Warning" : "Info"
            font.pixelSize: px16High
            font.weight: Font.Bold
            color: toastType == "success" ? focalisGreenOverlay : toastType == "error" ? focalisRedOverlay : toastType == "warning" ? focalisYellowOverlay : focalisSkyBlueOverlay
        }

        Text {
            text: toastMessage
            font.pixelSize: px14High
            color: toastType == "success" ? focalisGreenOverlay : toastType == "error" ? focalisRedOverlay : toastType == "warning" ? focalisYellowOverlay : focalisSkyBlueOverlay
        }
    }
}