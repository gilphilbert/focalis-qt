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

    ParallelAnimation {
        id: popupOpenAnimate
        running: false
        NumberAnimation {
            target: addEventBackground
            property: "opacity"
            to: 1
            duration: 300
            easing.type: Easing.InOutQuad
        }
        NumberAnimation { target: formContainer
            property: "y"
            to: addPopupRoot.height / 2 - formContainer.height / 2
            duration: 300
            easing.type: Easing.InOutQuad
        }
        onRunningChanged: {
            if (running) addPopupRoot.visible = true
        }
    }

    ParallelAnimation {
        id: popupCloseAnimate
        running: false
        NumberAnimation {
            target: addEventBackground
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: formContainer
            property: "y"
            to: parent.height
            duration: 300
            easing.type: Easing.InOutQuad
        }
        onRunningChanged: {
            if (!running) addPopupRoot.visible = false
        }
    }

    function openNewEvent() {
        summaryInput.text = ""
        locationInput.text = ""
        descriptionInput.text = ""
        selectedUser = userList[Object.keys(userList)[0]].id
        selectedDate = new Date()
        viewDate = new Date()
        selectedStartTime = "12:00"
        selectedEndTime = "13:00"
        isAllDay = false
        //visible = true
        popupOpenAnimate.start()
    }

    function closeNewEvent() {
        popupCloseAnimate.start()
    }

    property date startDate: new Date()
    property date endDate: new Date()

    // Helper to open the picker
    function showPicker(isStart) {
        pickerLoader.sourceComponent = pickerComp

        // Configure the picker based on mode
        var picker = pickerLoader.item
        picker.minDate = isStart ? new Date(1900, 0, 1) : startDate

        picker.accepted.connect(function(d) {
            if (isStart) {
                startDate = d
                endDate = d
            } else {
                endDate = d
            }
        })
        picker.open()
    }

    Component {
        id: pickerComp
        DatePicker {
            onClosed: pickerLoader.sourceComponent = null
        }
    }

    Loader { id: pickerLoader }

    // Semi-transparent dimming overlay mask
    Rectangle {
        anchors.fill: parent
        id: addEventBackground
        color: focalisPopupBackground
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: { }
        }
        opacity: 0
    }

    // Wide Layout Window Container (Optimized for 1080p width)
    Rectangle {
        id: formContainer
        width: 900 / 1920 * appWindow.width
        height: 680 / 1080 * appWindow.height
        radius: px32High
        color: focalisWhite
        //anchors.centerIn: parent
        x: parent.width / 2 - width / 2
        y: parent.height

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

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: px40High

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: px16Wide

                    // B. User Identity Assignment Row Links
                    ColumnLayout {
                        spacing: px6High
                        Layout.fillWidth: true
                        Text {
                            text: "Family member"
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

                    // A. Title Text Box
                    ColumnLayout {
                        spacing: px6High
                        Layout.fillWidth: true
                        Text {
                            text: "Title"
                            font.pixelSize: px13High
                            font.weight: Font.Bold
                            color: focalisMidGray
                        }
                        TextField {
                            id: summaryInput
                            font.pixelSize: px16High
                            Layout.fillWidth: true
                            padding: px14High
                            background: Rectangle {
                                radius: px12High
                                border.color: parent.activeFocus ? focalisSkyBlue : focalisLightishGray
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
                                text: "Time and date"
                                font.pixelSize: px13High
                                font.weight: Font.Bold
                                color: focalisMidGray
                            }
                        }

                        // Start & End ComboBox Array Container Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: px16Wide
                            // Smoothly fade out selectors visually when locked out
                            opacity: addPopupRoot.isAllDay ? 0.3 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            // Start Date Input
                            Button {
                                text: startDate.toLocaleDateString()
                                onClicked: showPicker(true)
                                padding: px14High

                                contentItem: Text {
                                    text: parent.text
                                    color: flocalisDarkGray // Set your desired color here
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                background: Rectangle {
                                    width: 200
                                    color: focalisWhite
                                    border.width: 1
                                    border.color: focalisLightishGray
                                    radius: px12High
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: px16Wide
                            // Smoothly fade out selectors visually when locked out
                            opacity: addPopupRoot.isAllDay ? 0.3 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            // End Date Input
                            Button {
                                text: endDate.toLocaleDateString()
                                onClicked: showPicker(false)
                                padding: px14High

                                contentItem: Text {
                                    text: parent.text
                                    color: flocalisDarkGray // Set your desired color here
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                background: Rectangle {
                                    width: 200
                                    color: focalisWhite
                                    border.width: 1
                                    border.color: focalisLightishGray
                                    radius: px12High
                                }
                            }
                        }
                    }

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

                    // D. Location Field & Description Text Space Frame
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: px16Wide
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: px6High
                            TextField {
                                id: locationInput
                                placeholderText: "Add location"
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
                            TextField {
                                id: descriptionInput
                                placeholderText: "Add description"
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
                    onClicked: closeNewEvent() //addPopupRoot.visible = false
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
                        var startTimestamp = 0
                        var endTimestamp = 0

                        if (addPopupRoot.isAllDay) {
                            // All day events anchor down across a flat 24-hour cycle frame
                            var sDate = new Date(addPopupRoot.selectedDate.getTime())
                            sDate.setHours(0, 0, 0, 0)
                            startTimestamp = Math.floor(sDate.getTime() / 1000)

                            var eDate = new Date(addPopupRoot.selectedDate.getTime())
                            eDate.setHours(23, 59, 59, 0)
                            endTimestamp = Math.floor(eDate.getTime() / 1000)
                        } else {
                            // Extract the separate start and end timestamps explicitly
                            var startParts = addPopupRoot.selectedStartTime.split(":")
                            var targetStartDate = new Date(addPopupRoot.selectedDate.getTime())
                            targetStartDate.setHours(parseInt(startParts[0]), parseInt(startParts[1]), 0, 0)
                            startTimestamp = Math.floor(targetStartDate.getTime() / 1000)

                            var endParts = addPopupRoot.selectedEndTime.split(":")
                            var targetEndDate = new Date(addPopupRoot.selectedDate.getTime())
                            targetEndDate.setHours(parseInt(endParts[0]), parseInt(endParts[1]), 0, 0)
                            endTimestamp = Math.floor(targetEndDate.getTime() / 1000)
                        }
                       //var startUnix = Math.floor(startDateTimePicker.selectedDate.getTime() / 1000)
                       //var endUnix = Math.floor(endDateTimePicker.selectedDate.getTime() / 1000)

                       // Grab the active value out of your dynamic dynamic user selection dropdown
                       var currentUserId = addPopupRoot.selectedUser

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
                       )
                   }
                }
            }
        }
    }

    // =========================================================
    // PARSING HELPER JAVASCRIPT LOGIC
    // =========================================================
    function getDaysInMonthModel(d) {
        let firstDay = new Date(d.getFullYear(), d.getMonth(), 1).getDay() //day of week, e.g. 1 = Monday
        let daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate() //days in the month, eg. 31
        let list = []
        let i = 0
        for (i = 0; i < firstDay; i++) list.push({day: 0, fullDate: new Date()})
        for (i = 1; i <= daysInMonth; i++) {
            list.push({day: i, fullDate: new Date(d.getFullYear(), d.getMonth(), i)})
        }
        return list
    }

    function isSameDate(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate()
    }

    function generateTimeSlots() {
        let s = []
        for (let h = 0; h < 24; h++) {
            let hs = h < 10 ? "0" + h : "" + h
            s.push(hs + ":00")
            s.push(hs + ":30")
        }
        return s
    }

    /*
    function submitEventToBackend() {
        if (summaryInput.text.trim() === "") return

        var startTimestamp = 0
        var endTimestamp = 0

        if (addPopupRoot.isAllDay) {
            // All day events anchor down across a flat 24-hour cycle frame
            var sDate = new Date(addPopupRoot.selectedDate.getTime())
            sDate.setHours(0, 0, 0, 0)
            startTimestamp = Math.floor(sDate.getTime() / 1000)

            var eDate = new Date(addPopupRoot.selectedDate.getTime())
            eDate.setHours(23, 59, 59, 0)
            endTimestamp = Math.floor(eDate.getTime() / 1000)
        } else {
            // Extract the separate start and end timestamps explicitly
            var startParts = addPopupRoot.selectedStartTime.split(":")
            var targetStartDate = new Date(addPopupRoot.selectedDate.getTime())
            targetStartDate.setHours(parseInt(startParts[0]), parseInt(startParts[1]), 0, 0)
            startTimestamp = Math.floor(targetStartDate.getTime() / 1000)

            var endParts = addPopupRoot.selectedEndTime.split(":")
            var targetEndDate = new Date(addPopupRoot.selectedDate.getTime())
            targetEndDate.setHours(parseInt(endParts[0]), parseInt(endParts[1]), 0, 0)
            endTimestamp = Math.floor(targetEndDate.getTime() / 1000)
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
        }

        var xhr = new XMLHttpRequest()
        xhr.open("POST", "http://your-go-service-ip:8080/api/calendar", true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                addPopupRoot.visible = false
                addPopupRoot.eventSaved()
            }
        }
        xhr.send(JSON.stringify(postPayload))
    }*/

    function addCalendarEvent(userId, summary, location, description, startTime, endTime, isAllDay, isBusy) {
        // 1. Create the standard XMLHttp object
        var xhr = new XMLHttpRequest()

        // 2. Format the target URL dynamically matching your Gin path
        var url = "http://localhost:8080/api/calendar/events/add/" + encodeURIComponent(userId)

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")

        // 3. Setup the state handler to verify the transmission
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 201) {
                    var response = JSON.parse(xhr.responseText)
                    console.log("Event created successfully! Database ID:", response.id)
                    addPopupRoot.visible = false
                    toast.show("success", "Added to calendar")

                    // Optional: Clear form inputs or trigger a UI success toast here
                } else {
                    console.error("Failed to save event. Status:", xhr.status, "Response:", xhr.responseText)
                }
            }
        }

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
        }

        // 5. Fire off the payload down the network wire
        xhr.send(JSON.stringify(payload))
    }
}