import QtQuick
import QtQuick.Controls

Label {
    property string name
    property string tagColor

    text: name
    font.pixelSize: 20
    color: shadeColor(tagColor, -60)
    topPadding: font.pixelSize / 2
    bottomPadding: topPadding
    leftPadding: (font.pixelSize * 2) + (font.pixelSize / 3)
    rightPadding: font.pixelSize / 1.6
    background: Rectangle {
        color: tagColor.substring(0, 7)
        radius: 100
    }
    Rectangle {
        id: circleBg
        color: shadeColor(tagColor, -20)
        radius: 100
        height: parent.height * 0.8
        width: height
        //opacity: 0.15
        anchors.left: parent.left
        anchors.leftMargin: parent.height * 0.1
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        text: name.substring(0, 1)
        font.pixelSize: 20
        color: "white"
        anchors.centerIn: circleBg
    }

    function shadeColor(color, percent) {

        var R = parseInt(color.substring(1,3),16);
        var G = parseInt(color.substring(3,5),16);
        var B = parseInt(color.substring(5,7),16);

        R = parseInt(R * (100 + percent) / 100);
        G = parseInt(G * (100 + percent) / 100);
        B = parseInt(B * (100 + percent) / 100);

        R = (R<255)?R:255;
        G = (G<255)?G:255;
        B = (B<255)?B:255;

        R = Math.round(R)
        G = Math.round(G)
        B = Math.round(B)

        var RR = ((R.toString(16).length===1)?"0"+R.toString(16):R.toString(16));
        var GG = ((G.toString(16).length===1)?"0"+G.toString(16):G.toString(16));
        var BB = ((B.toString(16).length===1)?"0"+B.toString(16):B.toString(16));

        return "#"+RR+GG+BB;
    }
}

