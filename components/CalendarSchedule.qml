import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {

    id: calendarRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    signal createNewEventRequested()

    // Holds the master processed calendar array for the UI to read
    property var processedSchedule: [[], [], [], [], [], [], [], []]
    property var hiddenUsers: ({})

    // Endpoint of your remote Go microservice
    property string apiEndpoint: "http://localhost:8080/api/calendar/schedule/"

    property int calendarViewOffsetWeeks: 0

    onCalendarViewOffsetWeeksChanged: function() {
        refreshCalendar()
    }


    // Fetch data immediately when the component loads
    //Component.onCompleted: {
    //    refreshCalendar();
    //}

    function fetchCalendarData(apiUrl) {
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

    function refreshCalendar() {
        fetchCalendarData(calendarRoot.apiEndpoint + (calendarViewOffsetWeeks * 8) + "/8") //for this view, we always want 8 days
            .then(function(data) {
                processJsonPayload(data);
            })
            .catch(function(error) {
                console.log("Error loading calendar data: " + error);
            });
    }

    function processJsonPayload(payload) {
        // Initialize 5 empty buckets for the next some days
        var tempSchedule = [[], [], [], [], [], [], [], []];
        var colorsMap = {};

        var today = new Date();
        today.setHours(0, 0, 0, 0);

        // Loop through each family member profile block
        for (var i = 0; i < payload.length; i++) {
            for (var j = 0; j < payload[i]["Events"].length; j++) {
                var event = payload[i]["Events"][j]

                var eventDate = new Date(event.Start * 1000);
                var formattedTime = eventDate.toLocaleTimeString(Qt.locale(), "h:mm AP");

                tempSchedule[i].push({
                    "id": event.ID,
                    "title": event.Summary,
                    "user": event.UserId,
                    "timeString": event.AllDay ? "All Day" : formattedTime,
                    "assignedUser": event.UserId,
                    "busy": event.Busy,
                    "attendees": event.Attendees,
                    "location": event.Location,
                    "description": event.Description
                });
            }
        }


        processedSchedule = tempSchedule

        for (var k = 0; k < tempSchedule.length; k++) {
            var columnItem = dayRepeater.itemAt(k);
            if (columnItem && columnItem.dayListView) {
                columnItem.dayListView.model = tempSchedule[k];
            }
        }
    }

    function normalizeColor(hex) {
        if (hex.length === 9 && hex.startsWith("#")) {
            // Move AA (alpha) from the end to the front for QML (#AARRGGBB)
            return "#" + hex.substring(7, 9) + hex.substring(1, 7);
        }
        return hex;
    }

    Rectangle {
        property int localPadding: px58Wide//parent.width * 0.03
        width: parent.width - localPadding
        height: parent.height - localPadding / 2
        radius: px30High
        anchors.horizontalCenter: parent.horizontalCenter
        color: focalisWhite


        //don't ask why, but the relativeHeight / relativeWidth functions don't work here. QML is weird.
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: px30High
            spacing: px24High

            RowLayout {
                Layout.fillWidth: true
                Image {
                    source: "qrc:images/icons/calendar.svg"
                    height: px20High
                    width: height
                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: focalisSkyBlue
                    }
                }
                Text {
                    text: "Family Agenda"
                    font.pixelSize: px22High
                    font.weight: 500
                    color: focalisBlack
                    rightPadding: px20Wide
                }

                Rectangle {
                    Layout.preferredHeight: px50High
                    Layout.preferredWidth: 171 / 1920 * appWindow.width
                    color: focalisLightGray
                    radius: px10High
                    RowLayout {
                        anchors.fill: parent
                        spacing: px5Wide
                        Text {
                            text: "←"
                            leftPadding: px10Wide
                            font.pixelSize: px22High
                            TapHandler {
                                onTapped: calendarViewOffsetWeeks--
                            }
                        }
                        Text {
                            text: "This week"
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            TapHandler {
                                onTapped: calendarViewOffsetWeeks = 0
                            }
                        }
                        Text {
                            text: "→"
                            rightPadding: px10Wide
                            font.pixelSize: px22High
                            TapHandler {
                                onTapped: calendarViewOffsetWeeks++
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: px50High
                    Layout.preferredWidth: 120 / 1920 * appWindow.width

                    radius: px10High
                    color: focalisSkyBlue

                    Text {
                        anchors.centerIn: parent
                        text: "+ New event"
                        color: focalisWhite
                        font.pixelSize: px16High
                        font.weight: 600
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            addEventPopup.openNewEvent()
                        }

                    }
                }
            }

            // Timeline row containing our day columns
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columnSpacing: px16High
                rowSpacing: px16High
                columns: 4

                Repeater {
                    model: 8 // Day index loops 0 - 4
                    id: dayRepeater

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: px14High
                        color: focalisLightGray

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: px16High
                            spacing: px16High

                            RowLayout {
                                Text {
                                    text: getTargetDayLabel(index)
                                    color: text === "TODAY" ? focalisSkyBlue : focalisBlack
                                    font.pixelSize: px18High
                                    font.weight: Font.Bold
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: (calendarRoot.processedSchedule[index].length > 0 ? calendarRoot.processedSchedule[index].length : "no") + " event" + (calendarRoot.processedSchedule[index].length > 1 || calendarRoot.processedSchedule[index].length === 0 ? "s" : "")
                                    color: focalisBlack
                                    font.pixelSize: px18High
                                }
                            }

                            ListView {
                                id: eventListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: px12High
                                clip: true

                                model: calendarRoot.processedSchedule[index]

                                delegate: Rectangle {
                                    width: eventListView.width
                                    height: 140 / 1920 * appWindow.height
                                    radius: px10High

                                    visible: !calendarRoot.hiddenUsers[modelData.assignedUser]
                                    color: userList[modelData.assignedUser].color
                                    opacity: modelData.busy ? 1.0 : 0.6

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: px16High

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: modelData.title
                                                font.pixelSize: px16High
                                                color: focalisWhite
                                                font.weight: Font.Bold
                                            }
                                            Text {
                                                text: modelData.timeString + " (" + userList[modelData.assignedUser].username + ")"
                                                font.pixelSize: px13High
                                                color: focalisWhite
                                                opacity: 0.8
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }
                                    TapHandler {
                                        onTapped: {
                                            eventDetailPopup.openEvent(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function getTargetDayLabel(offset) {
        let d = new Date();
        d.setDate(d.getDate() + (calendarViewOffsetWeeks * 8) + offset);
        if (offset === 0 && calendarViewOffsetWeeks === 0) return "Today";
        if (offset === 1 && calendarViewOffsetWeeks === 0) return "Tomorrow";
        return d.toLocaleDateString(Qt.locale(), "dddd, MMM d");
    }
}