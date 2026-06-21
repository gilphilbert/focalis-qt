import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard
import QtQuick.Layouts



import "./screens" as Screens
import "./components"

import Focalis.Core 1.0 // Import your native C++ module

/*
Window {
    id: window
    width: 1920
    height: 1080
    visible: true
    title: qsTr("Homestead")

    // Input panel, usually placed at the bottom
    InputPanel {
        id: inputPanel
        z: 99
        y: active ? window.height - height : window.height
        anchors.left: parent.left
        anchors.right: parent.right
    }
    Row {
        Column {
            Rectangle {
                id: navbar
                width: window.width * 0.06
                height: window.height
                color: "#F2F6F6"
                Column {

                }
            }
        }
        Column {
            Rectangle {
                id: content
                width: window.width - navbar.width
                height: window.height
                color: "#ffffff"

                Screens.Calendar {
                    width: parent.width
                    height: parent.height

                }
            }
        }
    }

}
*/

Window {
    id: appWindow
    width: 1920
    height: 1080
    visible: true
    title: "Family Command Center"

    property string focalisBlack: "#0e172a" //0f172a
    property string focalisWhite: "#ffffff"
    property string focalisSkyBlue: "#0EA5E9"
    property string focalisGreen: "#a4f489"
    property string focalisRed: "#f87263"
    property string focalisYellow: "#f9f871"

    property string focalisYellowOverlay: "#000000"
    property string focalisSkyBlueOverlay: "#FFFFFF"
    property string focalisGreenOverlay: "#000000"
    property string focalisRedOverlay: "#FFFFFF"

    property string focalisLightGray: "#f1f4f6"
    property string focalisLightishGray: "#E2E8F0"
    property string focalisMidGray: "#94A3B8"
    property string flocalisDarkGray: "#334155"

    property string focalisPopupBackground: "#AA0F172A"

    property real px6High: 6 / 1080 * appWindow.height
    property real px8High: 8 / 1080 * appWindow.height
    property real px10High: 10 / 1080 * appWindow.height
    property real px12High: 12 / 1080 * appWindow.height
    property real px13High: 13 / 1080 * appWindow.height
    property real px14High: 14 / 1080 * appWindow.height
    property real px15High: 15 / 1080 * appWindow.height
    property real px16High: 16 / 1080 * appWindow.height
    property real px18High: 18 / 1080 * appWindow.height
    property real px20High: 20 / 1080 * appWindow.height
    property real px22High: 22 / 1080 * appWindow.height
    property real px24High: 24 / 1080 * appWindow.height
    property real px30High: 30 / 1080 * appWindow.height
    property real px32High: 32 / 1080 * appWindow.height
    property real px35High: 35 / 1080 * appWindow.height
    property real px40High: 40 / 1080 * appWindow.height
    property real px48High: 48 / 1080 * appWindow.height
    property real px50High: 50 / 1080 * appWindow.height

    property real px5Wide: 5 / 1920 * appWindow.width
    property real px8Wide: 8 / 1920 * appWindow.width
    property real px10Wide: 10 / 1920 * appWindow.width
    property real px16Wide: 16 / 1920 * appWindow.width
    property real px20Wide: 20 / 1920 * appWindow.width
    property real px24Wide: 24 / 1920 * appWindow.width
    property real px26Wide: 26 / 1920 * appWindow.width
    property real px28Wide: 28 / 1920 * appWindow.width
    property real px30Wide: 30 / 1920 * appWindow.width
    property real px40Wide: 40 / 1920 * appWindow.width
    property real px58Wide: 58 / 1920 * appWindow.width

    property var userList: []
    property var userColors: ({})

    color: focalisLightGray

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =========================================================
        // 1. PERSISTENT NAVIGATION DOCK (120px wide)
        // =========================================================
        Rectangle {
            Layout.preferredWidth: 110
            Layout.fillHeight: true
            color: focalisWhite

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 40
                anchors.bottomMargin: 40
                spacing: 32

                // Application Branding / Logo Placeholder
                Rectangle {
                    width: 72
                    height: 72
                    radius: 20
                    color: focalisSkyBlue
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "F"
                        font.pixelSize: 36
                        anchors.centerIn: parent
                        font.weight: Font.Bold
                        color: focalisWhite
                    }
                }

                // Nav Buttons Group
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    NavButton {
                        icon: "qrc:images/icons/calendar.svg"
                        isActive: featureStack.currentIndex === 0
                        onClicked: featureStack.currentIndex = 0
                    }

                    NavButton {
                        icon: "qrc:images/icons/chores.svg"
                        isActive: featureStack.currentIndex === 1
                        onClicked: featureStack.currentIndex = 1
                    }

                    NavButton {
                        icon: "qrc:images/icons/prizes.svg"
                        isActive: featureStack.currentIndex === 2
                        onClicked: featureStack.currentIndex = 2
                    }

                    NavButton {
                        icon: "qrc:images/icons/brushing.svg"
                        isActive: featureStack.currentIndex === 3
                        onClicked: featureStack.currentIndex = 3
                    }

                    NavButton {
                        icon: "qrc:images/icons/settings.svg"
                        isActive: featureStack.currentIndex === 4
                        onClicked: featureStack.currentIndex = 4
                    }

                }
/*
                Spacer { Layout.fillHeight: true }

                // Settings Button at bottom
                NavButton {
                    iconText: "⚙️"
                    labelText: "Setup"
                    isActive: featureStack.currentIndex === 3
                    onClicked: featureStack.currentIndex = 3
                }
*/
            }
        }

        ColumnLayout {
            RowLayout {
                Layout.preferredHeight: parent.height * 0.095
                Layout.fillWidth: true
                Text {
                    text: `Good evening, <span style='color: ${focalisSkyBlue};'>Gilbert Household</span>!`
                    font.pixelSize: Window.height * 0.021
                    font.weight: Font.Bold
                    textFormat: Text.RichText
                    leftPadding: height
                }
            }

            // =========================================================
            // 2. DYNAMIC CONTENT STACK (1800px remaining)
            // =========================================================
            StackLayout {
                id: featureStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0 // Controls which screen layout is active

                CalendarSchedule {
                    id: calScheduleView
                }

//                RowLayout {
//                    spacing: 0
//                    Sidebar {
//                        id: choreSidebar
//                        userModel: goUserBridgeModel
//                        onUserSelected: function(name, current, lifetime, outstanding) {
//                            statsPopup.openPopup(name, current, lifetime, outstanding)
//                        }
//                    }
                    ChoreBoard {
                        id: choreBoard
                        //choreModel: goChoreBridgeModel
                    }
//                }

                Rectangle {
                    color: "#FFFFFF"
                    Text { text: "Reward Store Component"; anchors.centerIn: parent; font.pixelSize: 24 }
                }
            }
        }
    }

    // Centered Stats Popup
    StatsPopup {
        id: statsPopup
    }

    EventDetailPopup {
        id: eventDetailPopup
    }

    AddEventPopup {
        id: addEventPopup
        // Automatically refresh the UI data pipeline streams whenever a new record commits
        onEventSaved: {
            calScheduleView.refreshCalendar()
        }
    }

    Toast {
        id: toast
        // Automatically refresh the UI data pipeline streams whenever a new record commits
        //toastType: "error"
        //toastMessage: "Added to calendar"
    }

    Component.onCompleted: function () {
        //fetch users from the API
        fetchFromAPI("http://localhost:8080/api/users")
        .then(data => {
            //console.info(JSON.stringify(data))
            //userList = data
            let tmpList = {}
            data.forEach(user => {
                //console.info(user.id)
                tmpList[user.id] = user
            })
            //console.info(JSON.stringify(tmpList))
            userList = tmpList
        })
        //toast.show("success", "Added to calendar")
    }

    onUserListChanged: function () {
        //process users? Probably not, but...
        console.log(JSON.stringify(userList))
        if (Object.keys(userList).length > 0) {
            calScheduleView.refreshCalendar()
        }
    }

    function fetchFromAPI(apiUrl) {
        return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", apiUrl, true);
            xhr.setRequestHeader("Accept", "application/json");

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var jsonResponse = JSON.parse(xhr.responseText);
                            resolve(jsonResponse);
                        } catch (err) {
                            reject("Failed to parse Calendar JSON: " + err.message);
                        }
                    } else {
                        reject("Server returned status: " + xhr.status);
                    }
                }
            };

            xhr.send();
        });
    }

    function relativeWidth(px) {
        return Window.width * (px/1920)
    }
    function relativeHeight(px) {
        return Window.height * (px/1080)
    }

    InputPanel {
        id: inputPanel
        //property bool active: true

        z: 99

        x: (Window.width / 2) - (width / 2)
        y: active ? (Window.height - height) : Window.height
        width: parent.width * 0.4

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }
    }

    SSEClient {
        id: eventStream
        serverUrl: "http://localhost:8080/api/events"
        active: true

        onChoreCompleted: (data) => {
            console.info("Visual celebration for Chore ID: " + data.chore_id);
        }
        onChoresUpdated: (data) => {
            console.info("Re-rendering chore overview maps dynamically.");
        }
        onCalendarChanged: (data) => {
            calScheduleView.refreshCalendar()
        }
    }
}