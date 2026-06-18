import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: addPopupRoot
    anchors.fill: parent
    visible: false

    signal eventSaved()

    // --- State Management ---
    property date selectedDate: new Date()
    property date viewDate: new Date()
    property string selectedUser: ""
    property string selectedStartTime: "12:00"
    property string selectedEndTime: "13:00"
    property bool isAllDay: false // Controls field locking states

    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayLabels: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property var timeSlots: generateTimeSlots()

    function openNewEvent() {
        summaryInput.text = "";
        locationInput.text = "";
        descriptionInput.text = "";
        selectedUser = userList[Object.keys(userList)[0]].id
        selectedDate = new Date();
        viewDate = new Date();
        selectedStartTime = "12:00";
        selectedEndTime = "13:00";
        isAllDay = false;
        visible = true;
    }

    // Semi-transparent dimming overlay mask
    Rectangle {
        anchors.fill: parent
        color: focalisPopupBackground
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: { }
        }
    }

    // Wide Layout Window Container (Optimized for 1080p width)
    Rectangle {
        id: formContainer
        width: 1100 / 1920 * appWindow.width
        height: 680 / 1080 * appWindow.height
        radius: px32High
        color: focalisWhite
        anchors.centerIn: parent
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: { }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: px40High
            spacing: px24High

            Text {
                text: "New event"
                font.pixelSize: px32High
                font.weight: Font.Bold
                color: focalisBlack
            }

            // =========================================================
            // MAIN TWO-COLUMN WORKSPACE
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: px40High

                // -----------------------------------------------------
                // LEFT COLUMN: Dedicated Calendar Picker (Takes 45% Width)
                // -----------------------------------------------------
                ColumnLayout {
                    Layout.preferredWidth: 460 / 1920 * appWindow.width
                    Layout.fillHeight: true
                    spacing: px12High

                    Text {
                        text: "SELECT DATE"
                        font.pixelSize: px13High
                        font.weight: Font.Bold
                        color: focalisMidGray
                    }

                    // Month/Year Selector Header Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54 / 1080 * appWindow.height
                        color: focalisLightGray
                        radius: px12High
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: px8Wide
                            anchors.rightMargin: px8Wide
                            Button {
                                text: "◀"
                                flat: true
                                onClicked: addPopupRoot.viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1)
                            }
                            Text {
                                text: addPopupRoot.months[viewDate.getMonth()] + " " + viewDate.getFullYear()
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: px18High
                                font.weight: Font.Bold
                                color: focalisBlack
                            }
                            Button {
                                text: "▶"
                                flat: true
                                onClicked: addPopupRoot.viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1)
                            }
                        }
                    }

                    // Calendar Day Header Row labels
                    RowLayout {
                        Layout.fillWidth: true
                        height: px24High
                        Repeater {
                            model: addPopupRoot.dayLabels
                            Text {
                                text: modelData
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: px12High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }
                        }
                    }

                    // Grid Layout Generator Engine
                    GridLayout {
                        id: dayGrid
                        columns: 7
                        Layout.fillWidth: true
                        rowSpacing: px6High
                        columnSpacing: px6High

                        Repeater {
                            model: getDaysInMonthModel(viewDate)
                            Button {
                                id: dayBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: px48High
                                visible: modelData.day > 0
                                enabled: modelData.day > 0

                                property bool isSelected: isSameDate(addPopupRoot.selectedDate, modelData.fullDate)
                                property bool isToday: isSameDate(new Date(), modelData.fullDate)

                                background: Rectangle {
                                    radius: px10High
                                    color: dayBtn.isSelected ? focalisBlack : (dayBtn.isToday ? focalisLightGray/*"#EFF6FF"*/ : "transparent")
                                    border.color: dayBtn.isSelected ? focalisBlack : (dayBtn.isToday ? focalisSkyBlue : focalisLightishGray)
                                    border.width: dayBtn.isToday || dayBtn.isSelected ? 2 : 1
                                }
                                contentItem: Text {
                                    text: modelData.day > 0 ? modelData.day : ""
                                    font.pixelSize: px15High
                                    font.weight: dayBtn.isSelected ? Font.Black : Font.Medium
                                    color: dayBtn.isSelected ? focalisWhite : focalisBlack //"#1E293B"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: addPopupRoot.selectedDate = modelData.fullDate
                            }
                        }
                    }
                    Spacer { Layout.fillHeight: true }
                }

                // Vertical Divider Separator Line
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: focalisLightishGray
                }

                // -----------------------------------------------------
                // RIGHT COLUMN: Input Forms Fields Container Area (55% Width)
                // -----------------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: px16Wide

                    // A. Title Text Box
                    ColumnLayout {
                        spacing: px6High
                        Layout.fillWidth: true
                        Text {
                            text: "EVENT TITLE"
                            font.pixelSize: px13High
                            font.weight: Font.Bold
                            color: focalisMidGray
                        }
                        TextField {
                            id: summaryInput
                            placeholderText: "What's happening?"
                            font.pixelSize: px16High
                            Layout.fillWidth: true
                            padding: px14High
                            background: Rectangle {
                                radius: px12High
                                border.color: parent.activeFocus ? focalisSkyBlue : focalisLightishGray
                            }
                        }
                    }

                    // B. User Identity Assignment Row Links
                    ColumnLayout {
                        spacing: px6High
                        Layout.fillWidth: true
                        Text {
                            text: "FAMILY MEMBER"
                            font.pixelSize: px13High
                            font.weight: Font.Bold
                            color: focalisMidGray
                        }
                        RowLayout {
                            spacing: px10High
                            Repeater {
                                model: Object.keys(userList)
                                Button {
                                    id: uBtn
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 46 / 1080 * appWindow.height
                                    checkable: true
                                    checked: addPopupRoot.selectedUser === modelData
                                    background: Rectangle {
                                        radius: px12High
                                        color: uBtn.checked ? focalisSkyBlue : focalisLightGray
                                    }
                                    contentItem: Text {
                                        anchors.fill: parent
                                        text: userList[modelData].username
                                        color: uBtn.checked ? focalisWhite : focalisMidGray
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: addPopupRoot.selectedUser = modelData
                                }
                            }
                        }
                    }

                    // C. Time Controls: All Day Toggle + Start/End Pickers
                    ColumnLayout {
                        spacing: px8Wide
                        Layout.fillWidth: true

                        // Row Layout housing title header alongside the All-Day Checkbox
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "TIME & DURATION"
                                font.pixelSize: px13High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }

                            Spacer { Layout.fillWidth: true }

                            // Modern Custom Interactive Toggle Switch
                            RowLayout {
                                spacing: px8Wide
                                Text {
                                    text: "All Day Event"
                                    font.pixelSize: px14High
                                    font.weight: Font.Bold
                                    color: focalisMidGray
                                }
                                Switch {
                                    id: allDaySwitch
                                    checked: addPopupRoot.isAllDay
                                    onCheckedChanged: addPopupRoot.isAllDay = checked
                                }
                            }
                        }

                        // Start & End ComboBox Array Container Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: px16Wide
                            // Smoothly fade out selectors visually when locked out
                            opacity: addPopupRoot.isAllDay ? 0.3 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            ColumnLayout {
                                Layout.fillWidth: true
                                ComboBox {
                                    id: startTimeCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: px48High
                                    enabled: !addPopupRoot.isAllDay // Lock runtime touch evaluations
                                    model: addPopupRoot.timeSlots
                                    currentIndex: 24 // 12:00
                                    onActivated: index => addPopupRoot.selectedStartTime = model[index]
                                    background: Rectangle {
                                        radius: px12High
                                        border.color: focalisLightishGray; color: parent.enabled ? focalisWhite : focalisLightGray
                                    }
                                }
                            }

                            Text {
                                text: "to"
                                font.pixelSize: px16High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                ComboBox {
                                    id: endTimeCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48 / 1080 * appWindow.height
                                    enabled: !addPopupRoot.isAllDay // Lock runtime touch evaluations
                                    model: addPopupRoot.timeSlots
                                    currentIndex: 26 // 13:00
                                    onActivated: index => addPopupRoot.selectedEndTime = model[index]
                                    background: Rectangle {
                                        radius: px12High
                                        border.color: focalisLightishGray
                                        color: parent.enabled ? focalisWhite : focalisLightGray
                                    }
                                }
                            }
                        }
                    }

                    // D. Location Field & Description Text Space Frame
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: px16Wide
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: px6High
                            Text {
                                text: "LOCATION"
                                font.pixelSize: px13High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }
                            TextField {
                                id: locationInput
                                placeholderText: "Optional"
                                font.pixelSize: px16High
                                Layout.fillWidth: true
                                padding: px12High
                                background: Rectangle {
                                    radius: px12High
                                    border.color: focalisLightishGray
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: px6High
                            Text {
                                text: "NOTES / NOTES"
                                font.pixelSize: px13High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }
                            TextField {
                                id: descriptionInput
                                placeholderText: "Optional notes"
                                font.pixelSize: px16High
                                Layout.fillWidth: true
                                padding: px12High
                                background: Rectangle {
                                    radius: px12High
                                    border.color: focalisLightishGray
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Separator Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: focalisLightishGray
            }

            // Action Execution Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: px16Wide
                Layout.preferredHeight: 50 / 1080 * appWindow.height
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        radius: px14High
                        color: focalisLightGray
                    }
                    contentItem: Text {
                        text: "Cancel"
                        font.pixelSize: px18High
                        font.weight: Font.Bold
                        color: focalisMidGray
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: addPopupRoot.visible = false
                }
                Button {
                    id: saveBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        radius: px14High
                        color: focalisSkyBlue
                    }
                    contentItem: Text {
                        text: "Save Event"
                        font.pixelSize: px18High
                        font.weight: Font.Bold
                        color: focalisWhite
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                       // Convert your QML Date pickers/times into standard Unix epoch integers (seconds)
                       // JavaScript Date.now() or dateObject.getTime() returns milliseconds, so we divide by 1000
                        var startTimestamp = 0;
                        var endTimestamp = 0;

                        if (addPopupRoot.isAllDay) {
                            // All day events anchor down across a flat 24-hour cycle frame
                            var sDate = new Date(addPopupRoot.selectedDate.getTime());
                            sDate.setHours(0, 0, 0, 0);
                            startTimestamp = Math.floor(sDate.getTime() / 1000);

                            var eDate = new Date(addPopupRoot.selectedDate.getTime());
                            eDate.setHours(23, 59, 59, 0);
                            endTimestamp = Math.floor(eDate.getTime() / 1000);
                        } else {
                            // Extract the separate start and end timestamps explicitly
                            var startParts = addPopupRoot.selectedStartTime.split(":");
                            var targetStartDate = new Date(addPopupRoot.selectedDate.getTime());
                            targetStartDate.setHours(parseInt(startParts[0]), parseInt(startParts[1]), 0, 0);
                            startTimestamp = Math.floor(targetStartDate.getTime() / 1000);

                            var endParts = addPopupRoot.selectedEndTime.split(":");
                            var targetEndDate = new Date(addPopupRoot.selectedDate.getTime());
                            targetEndDate.setHours(parseInt(endParts[0]), parseInt(endParts[1]), 0, 0);
                            endTimestamp = Math.floor(targetEndDate.getTime() / 1000);
                        }
                       //var startUnix = Math.floor(startDateTimePicker.selectedDate.getTime() / 1000);
                       //var endUnix = Math.floor(endDateTimePicker.selectedDate.getTime() / 1000);

                       // Grab the active value out of your dynamic dynamic user selection dropdown
                       var currentUserId = addPopupRoot.selectedUser;

                       // Execute your JS handler
                       addCalendarEvent(
                           currentUserId,
                           summaryInput.text,
                           locationInput.text,
                           descriptionInput.text,
                           startTimestamp,
                           endTimestamp,
                           allDaySwitch.checked,
                           true //busySwitch.checked
                       );
                   }
                }
            }
        }
    }

    // =========================================================
    // PARSING HELPER JAVASCRIPT LOGIC
    // =========================================================
    function getDaysInMonthModel(d) {
        let firstDay = new Date(d.getFullYear(), d.getMonth(), 1).getDay();
        let daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        let list = [];
        for (let i = 0; i < firstDay; i++) list.push({day: 0, fullDate: new Date()});
        for (let i = 1; i <= daysInMonth; i++) {
            list.push({day: i, fullDate: new Date(d.getFullYear(), d.getMonth(), i)});
        }
        return list;
    }

    function isSameDate(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();
    }

    function generateTimeSlots() {
        let s = [];
        for (let h = 0; h < 24; h++) {
            let hs = h < 10 ? "0" + h : "" + h;
            s.push(hs + ":00"); s.push(hs + ":30");
        }
        return s;
    }

    /*
    function submitEventToBackend() {
        if (summaryInput.text.trim() === "") return;

        var startTimestamp = 0;
        var endTimestamp = 0;

        if (addPopupRoot.isAllDay) {
            // All day events anchor down across a flat 24-hour cycle frame
            var sDate = new Date(addPopupRoot.selectedDate.getTime());
            sDate.setHours(0, 0, 0, 0);
            startTimestamp = Math.floor(sDate.getTime() / 1000);

            var eDate = new Date(addPopupRoot.selectedDate.getTime());
            eDate.setHours(23, 59, 59, 0);
            endTimestamp = Math.floor(eDate.getTime() / 1000);
        } else {
            // Extract the separate start and end timestamps explicitly
            var startParts = addPopupRoot.selectedStartTime.split(":");
            var targetStartDate = new Date(addPopupRoot.selectedDate.getTime());
            targetStartDate.setHours(parseInt(startParts[0]), parseInt(startParts[1]), 0, 0);
            startTimestamp = Math.floor(targetStartDate.getTime() / 1000);

            var endParts = addPopupRoot.selectedEndTime.split(":");
            var targetEndDate = new Date(addPopupRoot.selectedDate.getTime());
            targetEndDate.setHours(parseInt(endParts[0]), parseInt(endParts[1]), 0, 0);
            endTimestamp = Math.floor(targetEndDate.getTime() / 1000);
        }

        var postPayload = {
            "DisplayName": addPopupRoot.selectedUser,
            "Events": [{
                "Summary": summaryInput.text,
                "Location": locationInput.text,
                "Description": descriptionInput.text,
                "Start": startTimestamp,
                "End": endTimestamp,
                "AllDay": addPopupRoot.isAllDay,
                "Busy": true,
                "Attendees": []
            }]
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://your-go-service-ip:8080/api/calendar", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                addPopupRoot.visible = false;
                addPopupRoot.eventSaved();
            }
        };
        xhr.send(JSON.stringify(postPayload));
    }*/

    function addCalendarEvent(userId, summary, location, description, startTime, endTime, isAllDay, isBusy) {
        // 1. Create the standard XMLHttp object
        var xhr = new XMLHttpRequest();

        // 2. Format the target URL dynamically matching your Gin path
        var url = "http://localhost:8080/api/calendar/events/add/" + encodeURIComponent(userId);

        xhr.open("POST", url, true);
        xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");

        // 3. Setup the state handler to verify the transmission
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 201) {
                    var response = JSON.parse(xhr.responseText);
                    console.log("Event created successfully! Database ID:", response.id)
                    addPopupRoot.visible = false
                    toast.show("success", "Added to calendar")

                    // Optional: Clear form inputs or trigger a UI success toast here
                } else {
                    console.error("Failed to save event. Status:", xhr.status, "Response:", xhr.responseText);
                }
            }
        };

        // 4. Construct the payload matching your Go models.Event structure exactly
        var payload = {
            "Summary": summary,
            "Location": location,
            "Description": description,
            "Start": parseInt(startTime), // Ensure this is passed as a Unix integer timestamp
            "End": parseInt(endTime),     // Ensure this is passed as a Unix integer timestamp
            "AllDay": isAllDay ? true : false,
            "Busy": isBusy ? true : false,
            "Attendees": []               // Keeping empty for baseline integration tests
        };

        // 5. Fire off the payload down the network wire
        xhr.send(JSON.stringify(payload));
    }
}