import QtQuick
import QtQuick.Effects


Rectangle {
    id: dayDreamRoot

    height: parent.height
    width: parent.width
    x: 0
    y: -appWindow.height

    color: focalisSkyBlue

    state: ""

    function open() {
        state = "opened"
    }

    states: State {
        name: "opened"
        PropertyChanges { target: dayDreamRoot; y: 0 }
    }

    transitions: Transition {
        NumberAnimation {
            properties: "y"
            easing.type: Easing.InOutQuad
            duration: 200
        }
    }

    Image {
        anchors.fill: parent
        source: "https://live.staticflickr.com/1147/5115716716_8e46f6f151_b.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Text {
        text: "July 21 2026"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        leftPadding: 40
        bottomPadding: 40
        color: focalisWhite
        font.pixelSize: 80

        layer.enabled: true

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: focalisSkyBlueOverlay
            shadowBlur: 4
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 2
        }
    }


    MouseArea {
        anchors.fill: parent
        //onClicked: dayDreamRoot.y = -1080
        onClicked: parent.state = parent.state === "opened" ? "" : "opened"
    }
}
