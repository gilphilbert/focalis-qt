import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: addPopupRoot
    anchors.fill: parent
    visible: false

    signal eventSaved()

    // --- State Management ---
    property string currentStage: "form"
    property string selectedUser: ""
    property string currentPinInput: ""
    property bool isAllDay: false

    // Decoupled Date/Time Objects
    property date selectedStartDate: new Date()
    property date selectedEndDate: new Date()

    property int startHour: 9
    property int startMinute: 0
    property string startAmPm: "AM"

    property int endHour: 10
    property int endMinute: 0
    property string endAmPm: "AM"

    property date startCalendarMonth: new Date()
    property date endCalendarMonth: new Date()

    property string inSummary: ""

    function openNewEvent(evt) {
        var now = new Date()

        if (!evt) {
            summaryInput.text = ""
            locationInput.text = ""
            descriptionInput.text = ""
            selectedUser = ""
            isAllDay = false

            selectedStartDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            selectedEndDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            startHour = 9; startMinute = 0; startAmPm = "AM"
            endHour = 10; endMinute = 0; endAmPm = "AM"
        } else {
            summaryInput.text = evt.title
            descriptionInput.text = evt.description
            locationInput.text = evt.location
            selectedUser = evt.assignedUser
            isAllDay = evt.all_day
            selectedStartDate = new Date(evt.start * 1000)
            startHour = selectedStartDate.getHours()
            startMinute = selectedStartDate.getMinutes()
            selectedEndDate = new Date(evt.end * 1000)
            endHour = selectedEndDate.getHours()
            endMinute = selectedEndDate.getMinutes()
        }

        startCalendarMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        endCalendarMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        currentPinInput = ""
        currentStage = "form"
        popupOpenAnimate.start()
    }

    function closeNewEvent() { popupCloseAnimate.start() }

    function appendPinDigit(digit) {
        if (currentPinInput.length < 4) {
            currentPinInput += digit
            if (currentPinInput.length === 4) commitEventWithAuth()
        }
    }

    function triggerAuthorization() {
        if (summaryInput.text.trim() === "") {
            toast.show("error", "Event requires a title")
            return
        }
        currentPinInput = ""
        currentStage = "auth"
    }

    function handleStartDateChange(newDate) {
        selectedStartDate = newDate
        if (selectedStartDate > selectedEndDate) {
            selectedEndDate = new Date(selectedStartDate)
            endCalendarMonth = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), 1)
        }
        enforceTimeValidation()
    }

    function handleEndDateChange(newDate) {
        if (newDate < selectedStartDate) {
            toast.show("error", "End date cannot be before start date")
            return
        }
        selectedEndDate = newDate
        enforceTimeValidation()
    }

    function convertTo24Hour(hour, amPm) {
        var h = hour % 12
        if (amPm === "PM") h += 12
        return h
    }

    function enforceTimeValidation() {
        var startH24 = convertTo24Hour(startHour, startAmPm)
        var endH24 = convertTo24Hour(endHour, endAmPm)

        var start = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), selectedStartDate.getDate(), startH24, startMinute, 0)
        var end = new Date(selectedEndDate.getFullYear(), selectedEndDate.getMonth(), selectedEndDate.getDate(), endH24, endMinute, 0)

        if (end <= start) {
            var fallbackEnd = new Date(start.getTime() + 60 * 60 * 1000)
            selectedEndDate = new Date(fallbackEnd.getFullYear(), fallbackEnd.getMonth(), fallbackEnd.getDate())

            var rawH = fallbackEnd.getHours()
            endAmPm = rawH >= 12 ? "PM" : "AM"
            endHour = rawH % 12
            if (endHour === 0) endHour = 12
            endMinute = fallbackEnd.getMinutes()
        }
    }

    function commitEventWithAuth() {
        var startH24 = isAllDay ? 0 : convertTo24Hour(startHour, startAmPm)
        var startMins = isAllDay ? 0 : startMinute
        var endH24 = isAllDay ? 23 : convertTo24Hour(endHour, endAmPm)
        var endMins = isAllDay ? 59 : endMinute

        var startObj = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), selectedStartDate.getDate(), startH24, startMins, 0)
        var endObj = new Date(selectedEndDate.getFullYear(), selectedEndDate.getMonth(), selectedEndDate.getDate(), endH24, endMins, 0)

        var xhr = new XMLHttpRequest()
        var url = baseURL + "/calendar/events"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
        xhr.setRequestHeader("X-Adult-PIN", currentPinInput) // 🔑 Global PIN only verification

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 201) {
                    addPopupRoot.visible = false
                    toast.show("success", "Added to calendar")
                    eventSaved()
                } else {
                    currentPinInput = ""
                    var errorMsg = "Incorrect System PIN"
                    try { var response = JSON.parse(xhr.responseText); if (response.error) errorMsg = response.error } catch(e){}
                    toast.show("error", errorMsg)
                }
            }
        }

        var payload = {
            "summary": summaryInput.text,
            "user_id": selectedUser,
            "location": locationInput.text,
            "description": descriptionInput.text,
            "start": Math.floor(startObj.getTime() / 1000),
            "end": Math.floor(endObj.getTime() / 1000),
            "all_day": isAllDay,
            "busy": true,
            "attendees": []
        }
        xhr.send(JSON.stringify(payload))
    }

    Rectangle { id: addEventBackground; anchors.fill: parent; color: focalisPopupBackground; opacity: 0 }

    Rectangle {
        id: centralContainer
        width: 620 / 1920 * appWindow.width
        height: (currentStage === "auth" ? 540 : 660) / 1080 * appWindow.height
        radius: px24High
        color: focalisWhite
        x: parent.width / 2 - width / 2
        y: (parent.height - height) / 2

        border.color: focalisLightishGray
        border.width: 1

        Behavior on height { NumberAnimation { duration: 180 } }

        Item {
            id: innerFormContainer
            anchors.fill: parent

            ColumnLayout {
                id: mainFormLayout
                anchors.fill: parent
                spacing: px16High
                visible: addPopupRoot.currentStage === "form"
                anchors.margins: px40High

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Create New Event"
                        font.pixelSize: px24High
                        font.bold: true
                        color: focalisBlack
                    }
                }

                ColumnLayout {
                    spacing: px4High
                    Text {
                        text: "Select calendar"
                        font.pixelSize: px12High
                        font.bold: true
                        color: focalisMidGray
                    }
                    RowLayout {
                        spacing: px8Wide
                        Repeater {
                            model: Object.keys(userList)
                            delegate: Button {
                                Layout.preferredWidth: 90 / 1920 * appWindow.width
                                Layout.preferredHeight: 40 / 1080 * appWindow.height
                                background: Rectangle {
                                    radius: px8High
                                    color: userList[modelData].color || focalisLightGray
                                    border.width: addPopupRoot.selectedUser === modelData ? 3 : 0
                                    border.color: focalisBlack
                                }
                                contentItem: Text {
                                    text: userList[modelData].username
                                    color: focalisWhite
                                    font.bold: true
                                    font.pixelSize: px13High
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: addPopupRoot.selectedUser = modelData
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: px4High
                    Layout.fillWidth: true
                    Text {
                        text: "Title"
                        font.pixelSize: px12High
                        font.bold: true
                        color: focalisMidGray
                    }
                    TextField {
                        id: summaryInput
                        font.pixelSize: px16High
                        Layout.fillWidth: true
                        padding: px12High
                        background: Rectangle {
                            radius: px10High
                            border.color: focalisLightishGray
                        }
                    }
                }

                ColumnLayout {
                    id: scheduleSection
                    spacing: px6High
                    Layout.fillWidth: true
                    Text {
                        text: "Date & Time"
                        font.pixelSize: px12High
                        font.bold: true
                        color: focalisMidGray
                    }

                    RowLayout {
                        id: startRowContext
                        spacing: px12High
                        Layout.fillWidth: true

                        Button {
                            id: startDateFieldBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: px8High
                                border.color: focalisLightishGray
                                color: focalisWhite
                            }
                            contentItem: Text {
                                text: addPopupRoot.selectedStartDate.toLocaleDateString(Qt.locale(), "MMM d, yyyy")
                                font.pixelSize: px14High
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: px10High
                            }
                            onClicked: startDatePopup.open()
                        }

                        Button {
                            id: startTimeFieldBtn
                            visible: !addPopupRoot.isAllDay
                            Layout.preferredWidth: 150 / 1920 * appWindow.width; Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: px8High
                                border.color: focalisLightishGray
                                color: focalisWhite
                            }
                            contentItem: Text {
                                text: addPopupRoot.startHour + ":" + addPopupRoot.startMinute.toString().padStart(2, '0') + " " + addPopupRoot.startAmPm
                                font.pixelSize: px14High
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: startTimePopup.open()
                        }
                    }

                    RowLayout {
                        id: endRowContext
                        spacing: px12High
                        Layout.fillWidth: true

                        Button {
                            id: endDateFieldBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: px8High
                                border.color: focalisLightishGray
                                color: focalisWhite
                            }
                            contentItem: Text {
                                text: addPopupRoot.selectedEndDate.toLocaleDateString(Qt.locale(), "MMM d, yyyy")
                                font.pixelSize: px14High
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: px10High
                            }
                            onClicked: endDatePopup.open()
                        }

                        Button {
                            id: endTimeFieldBtn
                            visible: !addPopupRoot.isAllDay
                            Layout.preferredWidth: 150 / 1920 * appWindow.width
                            Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: px8High
                                border.color: focalisLightishGray
                                color: focalisWhite
                            }
                            contentItem: Text {
                                text: addPopupRoot.endHour + ":" + addPopupRoot.endMinute.toString().padStart(2, '0') + " " + addPopupRoot.endAmPm
                                font.pixelSize: px14High
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: endTimePopup.open()
                        }
                    }
                }

                RowLayout {
                    spacing: px8Wide
                    Text {
                        text: "All Day Event"
                        font.pixelSize: px13High
                        font.bold: true
                        color: focalisMidGray
                    }
                    Switch {
                        checked: addPopupRoot.isAllDay
                        onCheckedChanged: addPopupRoot.isAllDay = checked
                    }
                }

                TextField {
                    id: locationInput
                    placeholderText: "Add location"
                    Layout.fillWidth: true; padding: px12High
                    background: Rectangle { radius: px10High
                        border.color: focalisLightishGray
                    }
                }
                TextField {
                    id: descriptionInput
                    placeholderText: "Add description"
                    Layout.fillWidth: true; padding: px12High
                    background: Rectangle {
                        radius: px10High
                        border.color: focalisLightishGray
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: px16Wide
                    Layout.preferredHeight: 48 / 1080 * appWindow.height
                    Button {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        background: Rectangle {
                            radius: px12High
                            color: focalisLightGray
                        }
                        contentItem: Text {
                            text: "Cancel"
                            font.pixelSize: px16High
                            font.bold: true
                            color: focalisMidGray
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: closeNewEvent()
                    }
                    Button {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        enabled: addPopupRoot.selectedUser !== ""
                        background: Rectangle {
                            radius: px12High
                            color: parent.enabled ? focalisSkyBlue : focalisLightishGray
                        }
                        contentItem: Text {
                            text: "Save Event"
                            font.pixelSize: px16High
                            font.bold: true
                            color: focalisWhite
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: triggerAuthorization()
                    }
                }
            }

            // STAGE 2: CLEAN SYSTEM-WIDE AUTH PIN PAD
            ColumnLayout {
                anchors.fill: parent
                spacing: px16High
                visible: addPopupRoot.currentStage === "auth"
                anchors.margins: px40High

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "System Authorization"
                        font.pixelSize: px24High
                        font.bold: true
                        color: focalisBlack
                    }
                }

                ColumnLayout {
                    spacing: px18High
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true

                    Text {
                        text: "Enter PIN"
                        font.pixelSize: px14High
                        font.bold: true
                        color: focalisMidGray
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        spacing: px14High
                        Layout.alignment: Qt.AlignHCenter
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: px18High
                                height: px18High
                                radius: width/2
                                color: index < addPopupRoot.currentPinInput.length ? focalisSkyBlue : focalisLightGray
                            }
                        }
                    }

                    GridLayout {
                        columns: 3
                        rowSpacing: px8High
                        columnSpacing: px14High
                        Layout.alignment: Qt.AlignHCenter
                        Repeater {
                            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                            delegate: Button {
                                text: modelData
                                Layout.preferredWidth: px64High
                                Layout.preferredHeight: px64High
                                background: Rectangle {
                                    radius: px14High
                                    color: focalisLightGray
                                }
                                onClicked: appendPinDigit(modelData)
                            }
                        }
                        Button {
                            text: "Back"
                            Layout.preferredWidth: px64High
                            Layout.preferredHeight: px64High
                            onClicked: addPopupRoot.currentStage = "form"
                            background: Rectangle {
                                radius: px14High
                                color: focalisLightGray
                            }
                        }
                        Button {
                            text: "0"
                            Layout.preferredWidth: px64High
                            Layout.preferredHeight: px64High
                            background: Rectangle {
                                radius: px14High
                                color: focalisLightGray
                            }
                            onClicked: appendPinDigit("0")
                        }
                        Button {
                            text: "⌫"
                            Layout.preferredWidth: px64High
                            Layout.preferredHeight: px64High
                            background: Rectangle {
                                radius: px14High
                                color: focalisLightGray
                            }
                            onClicked: addPopupRoot.currentPinInput = addPopupRoot.currentPinInput.slice(0, -1)
                        }
                    }
                }
            }
        }

        // =========================================================================
        // LOCAL FLOATING POPUPS
        // =========================================================================
        Popup {
            id: startDatePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + startRowContext.x + startDateFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + startRowContext.y + startDateFieldBtn.y + startDateFieldBtn.height + 4
            width: 320 / 1920 * appWindow.width; height: 260 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Button { text: "◀"; flat: true; onClicked: startCalendarMonth = new Date(startCalendarMonth.getFullYear(), startCalendarMonth.getMonth() - 1, 1) }
                    Text { text: startCalendarMonth.toLocaleString(Qt.locale(), "MMMM yyyy"); font.pixelSize: px14High; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Button { text: "▶"; flat: true; onClicked: startCalendarMonth = new Date(startCalendarMonth.getFullYear(), startCalendarMonth.getMonth() + 1, 1) }
                }
                GridLayout {
                    columns: 7; Layout.fillWidth: true; Layout.fillHeight: true; rowSpacing: 2; columnSpacing: 2
                    Repeater { model: ["S","M","T","W","T","F","S"]; delegate: Text { text: modelData; font.pixelSize: px12High; font.bold: true; color: focalisMidGray; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true } }
                    Repeater {
                        model: generateMonthGrid(startCalendarMonth, addPopupRoot.selectedStartDate)
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                            color: modelData.isCurrent ? (modelData.isSelected ? focalisSkyBlue : "transparent") : "transparent"
                            opacity: modelData.isCurrent ? 1.0 : 0.2
                            Text { text: modelData.day; font.pixelSize: px12High; font.bold: modelData.isSelected; color: modelData.isSelected ? focalisWhite : focalisBlack; anchors.centerIn: parent }
                            TapHandler {
                                enabled: modelData.isCurrent
                                onTapped: {
                                    handleStartDateChange(modelData.fullDate)
                                    startDatePopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        Popup {
            id: endDatePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + endRowContext.x + endDateFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + endRowContext.y + endDateFieldBtn.y + endDateFieldBtn.height + 4
            width: 320 / 1920 * appWindow.width; height: 260 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Button { text: "◀"; flat: true; onClicked: endCalendarMonth = new Date(endCalendarMonth.getFullYear(), endCalendarMonth.getMonth() - 1, 1) }
                    Text { text: endCalendarMonth.toLocaleString(Qt.locale(), "MMMM yyyy"); font.pixelSize: px14High; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Button { text: "▶"; flat: true; onClicked: endCalendarMonth = new Date(endCalendarMonth.getFullYear(), endCalendarMonth.getMonth() + 1, 1) }
                }
                GridLayout {
                    columns: 7; Layout.fillWidth: true; Layout.fillHeight: true; rowSpacing: 2; columnSpacing: 2
                    Repeater { model: ["S","M","T","W","T","F","S"]; delegate: Text { text: modelData; font.pixelSize: px12High; font.bold: true; color: focalisMidGray; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true } }
                    Repeater {
                        model: generateMonthGrid(endCalendarMonth, addPopupRoot.selectedEndDate)
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                            color: modelData.isCurrent ? (modelData.isSelected ? focalisSkyBlue : "transparent") : "transparent"
                            opacity: modelData.isCurrent ? 1.0 : 0.2
                            Text { text: modelData.day; font.pixelSize: px12High; font.bold: modelData.isSelected; color: modelData.isSelected ? focalisWhite : focalisBlack; anchors.centerIn: parent }
                            TapHandler { enabled: modelData.isCurrent; onTapped: { handleEndDateChange(modelData.fullDate); endDatePopup.close() } }
                        }
                    }
                }
            }
        }

        Popup {
            id: startTimePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + startRowContext.x + startTimeFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + startRowContext.y + startTimeFieldBtn.y + startTimeFieldBtn.height + 4
            width: 220 / 1920 * appWindow.width; height: 180 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                Tumbler {
                    id: startHourTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [1,2,3,4,5,6,7,8,9,10,11,12]
                    currentIndex: model.indexOf(addPopupRoot.startHour)
                    onCurrentIndexChanged: { addPopupRoot.startHour = model[currentIndex]; enforceTimeValidation() }
                }
                Text { text: ":"; font.bold: true; font.pixelSize: px16High }
                Tumbler {
                    id: startMinTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [0,5,10,15,20,25,30,35,40,45,50,55]
                    currentIndex: model.indexOf(addPopupRoot.startMinute)
                    delegate: Text { text: modelData.toString().padStart(2, '0'); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: px14High; opacity: Tumbler.displacement === 0 ? 1.0 : 0.4 }
                    onCurrentIndexChanged: { addPopupRoot.startMinute = model[currentIndex]; enforceTimeValidation() }
                }
                Tumbler {
                    id: startAmPmTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: ["AM", "PM"]
                    currentIndex: model.indexOf(addPopupRoot.startAmPm)
                    onCurrentIndexChanged: { addPopupRoot.startAmPm = model[currentIndex]; enforceTimeValidation() }
                }
            }
        }

        Popup {
            id: endTimePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + endRowContext.x + endTimeFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + endRowContext.y + endTimeFieldBtn.y + endTimeFieldBtn.height + 4
            width: 220 / 1920 * appWindow.width; height: 180 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                Tumbler {
                    id: endHourTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [1,2,3,4,5,6,7,8,9,10,11,12]
                    currentIndex: model.indexOf(addPopupRoot.endHour)
                    onCurrentIndexChanged: { addPopupRoot.endHour = model[currentIndex]; enforceTimeValidation() }
                }
                Text { text: ":"; font.bold: true; font.pixelSize: px16High }
                Tumbler {
                    id: endMinTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [0,5,10,15,20,25,30,35,40,45,50,55]
                    currentIndex: model.indexOf(addPopupRoot.endMinute)
                    delegate: Text { text: modelData.toString().padStart(2, '0'); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: px14High; opacity: Tumbler.displacement === 0 ? 1.0 : 0.4 }
                    onCurrentIndexChanged: { addPopupRoot.endMinute = model[currentIndex]; enforceTimeValidation() }
                }
                Tumbler {
                    id: endAmPmTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: ["AM", "PM"]
                    currentIndex: model.indexOf(addPopupRoot.endAmPm)
                    onCurrentIndexChanged: { addPopupRoot.endAmPm = model[currentIndex]; enforceTimeValidation() }
                }
            }
        }
    }

    function generateMonthGrid(monthStartDate, currentSelectedDate) {
        var year = monthStartDate.getFullYear()
        var month = monthStartDate.getMonth()
        var firstDayIndex = new Date(year, month, 1).getDay()
        var totalDays = new Date(year, month + 1, 0).getDate()

        var gridCells = []
        for (var i = 0; i < firstDayIndex; i++) {
            gridCells.push({ "day": "", "isCurrent": false, "isSelected": false, "fullDate": new Date() })
        }
        for (var day = 1; day <= totalDays; day++) {
            var cellDate = new Date(year, month, day)
            var isSelected = (cellDate.getDate() === currentSelectedDate.getDate() &&
                              cellDate.getMonth() === currentSelectedDate.getMonth() &&
                              cellDate.getFullYear() === currentSelectedDate.getFullYear())
            gridCells.push({ "day": day.toString(), "isCurrent": true, "isSelected": isSelected, "fullDate": cellDate })
        }
        return gridCells
    }

    ParallelAnimation {
        id: popupOpenAnimate; running: false
        NumberAnimation { target: centralContainer; property: "scale"; from: 0; to: 1; duration: 180; easing.type: Easing.OutBack }
        NumberAnimation { target: addEventBackground; property: "opacity"; from: 0; to: 1; duration: 180 }
        onRunningChanged: { if (running) addPopupRoot.visible = true }
    }
    ParallelAnimation {
        id: popupCloseAnimate; running: false
        NumberAnimation { target: centralContainer; property: "scale"; from: 1; to: 0; duration: 150 }
        NumberAnimation { target: addEventBackground; property: "opacity"; from: 1; to: 0; duration: 150 }
        onRunningChanged: { if (!running) addPopupRoot.visible = false }
    }
}

/*
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: addPopupRoot
    anchors.fill: parent
    visible: false

    signal eventSaved()

    // --- State Management ---
    property string currentStage: "form"
    property string selectedUser: ""
    property string authUser: ""
    property string currentPinInput: ""
    property bool isAllDay: false

    // Decoupled Date/Time Objects
    property date selectedStartDate: new Date()
    property date selectedEndDate: new Date()

    property int startHour: 9
    property int startMinute: 0
    property string startAmPm: "AM"

    property int endHour: 10
    property int endMinute: 0
    property string endAmPm: "AM"

    property date startCalendarMonth: new Date()
    property date endCalendarMonth: new Date()

    function openNewEvent() {
        summaryInput.text = ""
        locationInput.text = ""
        descriptionInput.text = ""
        selectedUser = ""
        authUser = ""
        currentPinInput = ""
        currentStage = "form"
        isAllDay = false

        var now = new Date()
        selectedStartDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        selectedEndDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        startCalendarMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        endCalendarMonth = new Date(now.getFullYear(), now.getMonth(), 1)

        startHour = 9; startMinute = 0; startAmPm = "AM"
        endHour = 10; endMinute = 0; endAmPm = "AM"

        popupOpenAnimate.start()
    }

    function closeNewEvent() { popupCloseAnimate.start() }

    function appendPinDigit(digit) {
        if (currentPinInput.length < 4) {
            currentPinInput += digit
            if (currentPinInput.length === 4) commitEventWithAuth()
        }
    }

    function triggerAuthorization() {
        if (summaryInput.text.trim() === "") {
            toast.show("error", "Event requires a title")
            return
        }
        currentPinInput = ""
        authUser = (selectedUser !== "" && userList[selectedUser].role === "adult") ? selectedUser : ""
        currentStage = "auth"
    }

    function handleStartDateChange(newDate) {
        selectedStartDate = newDate
        if (selectedStartDate > selectedEndDate) {
            selectedEndDate = new Date(selectedStartDate)
            endCalendarMonth = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), 1)
        }
        enforceTimeValidation()
    }

    function handleEndDateChange(newDate) {
        if (newDate < selectedStartDate) {
            toast.show("error", "End date cannot be before start date")
            return
        }
        selectedEndDate = newDate
        enforceTimeValidation()
    }

    function convertTo24Hour(hour, amPm) {
        var h = hour % 12
        if (amPm === "PM") h += 12
        return h
    }

    function enforceTimeValidation() {
        var startH24 = convertTo24Hour(startHour, startAmPm)
        var endH24 = convertTo24Hour(endHour, endAmPm)

        var start = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), selectedStartDate.getDate(), startH24, startMinute, 0)
        var end = new Date(selectedEndDate.getFullYear(), selectedEndDate.getMonth(), selectedEndDate.getDate(), endH24, endMinute, 0)

        if (end <= start) {
            var fallbackEnd = new Date(start.getTime() + 60 * 60 * 1000)
            selectedEndDate = new Date(fallbackEnd.getFullYear(), fallbackEnd.getMonth(), fallbackEnd.getDate())

            var rawH = fallbackEnd.getHours()
            endAmPm = rawH >= 12 ? "PM" : "AM"
            endHour = rawH % 12
            if (endHour === 0) endHour = 12
            endMinute = fallbackEnd.getMinutes()
        }
    }

    function commitEventWithAuth() {
        if (authUser === "") {
            toast.show("error", "Select a verifying parent account")
            currentPinInput = ""
            return
        }

        var startH24 = isAllDay ? 0 : convertTo24Hour(startHour, startAmPm)
        var startMins = isAllDay ? 0 : startMinute
        var endH24 = isAllDay ? 23 : convertTo24Hour(endHour, endAmPm)
        var endMins = isAllDay ? 59 : endMinute

        var startObj = new Date(selectedStartDate.getFullYear(), selectedStartDate.getMonth(), selectedStartDate.getDate(), startH24, startMins, 0)
        var endObj = new Date(selectedEndDate.getFullYear(), selectedEndDate.getMonth(), selectedEndDate.getDate(), endH24, endMins, 0)

        var xhr = new XMLHttpRequest()
        var url = baseURL + "/calendar/events/" + encodeURIComponent(selectedUser)
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
        xhr.setRequestHeader("X-Adult-PIN", currentPinInput)
        xhr.setRequestHeader("X-Target-Adult-ID", authUser)

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 201) {
                    addPopupRoot.visible = false
                    toast.show("success", "Added to calendar")
                    eventSaved()
                } else {
                    currentPinInput = ""
                    var errorMsg = "Failed to save event"
                    try { var response = JSON.parse(xhr.responseText); if (response.error) errorMsg = response.error } catch(e){}
                    toast.show("error", errorMsg)
                }
            }
        }

        var payload = {
            "Summary": summaryInput.text,
            "Location": locationInput.text,
            "Description": descriptionInput.text,
            "Start": Math.floor(startObj.getTime() / 1000),
            "End": Math.floor(endObj.getTime() / 1000),
            "AllDay": isAllDay,
            "Busy": true,
            "Attendees": []
        }
        xhr.send(JSON.stringify(payload))
    }

    Rectangle { id: addEventBackground; anchors.fill: parent; color: focalisPopupBackground; opacity: 0 }

    Rectangle {
        id: centralContainer
        width: 620 / 1920 * appWindow.width
        height: (currentStage === "auth" ? 580 : 660) / 1080 * appWindow.height
        radius: px24High
        color: focalisWhite
        x: parent.width / 2 - width / 2
        y: (parent.height - height) / 2

        border.color: focalisLightishGray
        border.width: 1

        Behavior on height { NumberAnimation { duration: 180 } }

        // 📦 Form Content Container Item (Restores structural layout positioning margins)
        Item {
            id: innerFormContainer
            anchors.fill: parent
            anchors.margins: px36High

            ColumnLayout {
                id: mainFormLayout
                anchors.fill: parent
                anchors.margins: px40High
                spacing: px16High
                visible: addPopupRoot.currentStage === "form"

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Create New Event";
                        font.pixelSize: px20High
                        color: focalisBlack
                    }
                    Item { Layout.fillWidth: true }
                }

                ColumnLayout {
                    spacing: px4High
                    Text { text: "Select calendar"; font.pixelSize: px12High; font.bold: true; color: focalisMidGray }
                    RowLayout {
                        spacing: px8Wide
                        Repeater {
                            model: Object.keys(userList)
                            delegate: Button {
                                Layout.preferredWidth: 90 / 1920 * appWindow.width
                                Layout.preferredHeight: 40 / 1080 * appWindow.height
                                background: Rectangle {
                                    radius: px8High
                                    color: addPopupRoot.selectedUser === modelData ? userList[modelData].color : focalisLightGray
                                    //border.width: addPopupRoot.selectedUser === modelData ? 3 : 0
                                    //border.color: focalisBlack
                                }
                                contentItem:
                                    Text {
                                      text: userList[modelData].username;
                                      color: focalisWhite;
                                      font.bold: true;
                                      font.pixelSize: px13High;
                                      horizontalAlignment: Text.AlignHCenter;
                                      verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: addPopupRoot.selectedUser = modelData
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: px4High; Layout.fillWidth: true
                    Text { text: "Title"; font.pixelSize: px12High; font.bold: true; color: focalisMidGray }
                    TextField {
                        id: summaryInput
                        font.pixelSize: px16High; Layout.fillWidth: true; padding: px12High
                        background: Rectangle { radius: px10High; border.color: focalisLightishGray }
                    }
                }

                ColumnLayout {
                    id: scheduleSection
                    spacing: px6High
                    Layout.fillWidth: true
                    Text { text: "Date & Time Setup"; font.pixelSize: px12High; font.bold: true; color: focalisMidGray }

                    RowLayout {
                        id: startRowContext
                        spacing: px12Wide
                        Layout.fillWidth: true

                        Button {
                            id: startDateFieldBtn
                            Layout.fillWidth: true; Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle { radius: px8High; border.color: focalisLightishGray; color: focalisLightGray }
                            contentItem: Text { text: addPopupRoot.selectedStartDate.toLocaleDateString(Qt.locale(), "MMM d, yyyy"); font.pixelSize: px14High; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: px10High }
                            onClicked: startDatePopup.open()
                        }

                        Button {
                            id: startTimeFieldBtn
                            visible: !addPopupRoot.isAllDay
                            Layout.preferredWidth: 150 / 1920 * appWindow.width; Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle { radius: px8High; border.color: focalisLightishGray; color: focalisLightGray }
                            contentItem: Text { text: addPopupRoot.startHour + ":" + addPopupRoot.startMinute.toString().padStart(2, '0') + " " + addPopupRoot.startAmPm; font.pixelSize: px14High; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: startTimePopup.open()
                        }
                    }

                    RowLayout {
                        id: endRowContext
                        spacing: px12Wide
                        Layout.fillWidth: true

                        Button {
                            id: endDateFieldBtn
                            Layout.fillWidth: true; Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle { radius: px8High; border.color: focalisLightishGray; color: focalisLightGray }
                            contentItem: Text { text: addPopupRoot.selectedEndDate.toLocaleDateString(Qt.locale(), "MMM d, yyyy"); font.pixelSize: px14High; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: px10High }
                            onClicked: endDatePopup.open()
                        }

                        Button {
                            id: endTimeFieldBtn
                            visible: !addPopupRoot.isAllDay
                            Layout.preferredWidth: 150 / 1920 * appWindow.width; Layout.preferredHeight: 44 / 1080 * appWindow.height
                            background: Rectangle { radius: px8High; border.color: focalisLightishGray; color: focalisLightGray }
                            contentItem: Text { text: addPopupRoot.endHour + ":" + addPopupRoot.endMinute.toString().padStart(2, '0') + " " + addPopupRoot.endAmPm; font.pixelSize: px14High; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: endTimePopup.open()
                        }
                    }
                }

                RowLayout {
                    spacing: px8Wide
                    Text { text: "All Day Event"; font.pixelSize: px13High; font.bold: true; color: focalisMidGray }
                    Switch { checked: addPopupRoot.isAllDay; onCheckedChanged: addPopupRoot.isAllDay = checked }
                }

                TextField { id: locationInput; placeholderText: "Add location"; Layout.fillWidth: true; padding: px12High; background: Rectangle { radius: px10High; border.color: focalisLightishGray } }
                TextField { id: descriptionInput; placeholderText: "Add description"; Layout.fillWidth: true; padding: px12High; background: Rectangle { radius: px10High; border.color: focalisLightishGray } }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true; spacing: px16Wide; Layout.preferredHeight: 48 / 1080 * appWindow.height
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        background: Rectangle { radius: px12High; color: focalisLightGray }
                        contentItem: Text { text: "Cancel"; font.pixelSize: px16High; font.bold: true; color: focalisMidGray; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: closeNewEvent()
                    }
                    Button {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        enabled: addPopupRoot.selectedUser !== ""
                        background: Rectangle { radius: px12High; color: parent.enabled ? focalisSkyBlue : focalisLightishGray }
                        contentItem: Text { text: "Save Event"; font.pixelSize: px16High; font.bold: true; color: focalisWhite; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: triggerAuthorization()
                    }
                }
            }

            // STAGE 2: AUTH SEGMENT
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: px40High
                spacing: px16High
                visible: addPopupRoot.currentStage === "auth"

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Authorization"
                        font.pixelSize: px20High
                        color: focalisBlack
                    }
                    Item { Layout.fillWidth: true }
                }

                ColumnLayout {
                    spacing: px6High;
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "Select account:"
                        font.pixelSize: px13High
                        font.bold: true
                        color: focalisMidGray
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        spacing: px12Wide
                        Repeater {
                            model: Object.keys(userList)
                            delegate: Button {
                                visible: userList[modelData].role === "adult"
                                Layout.preferredWidth: 110 / 1920 * appWindow.width
                                Layout.preferredHeight: 44 / 1080 * appWindow.height
                                background: Rectangle {
                                    radius: px10High
                                    color: userList[modelData].color || focalisLightGray
                                    border.width: addPopupRoot.authUser === modelData ? 3 : 0
                                    border.color: focalisBlack
                                }
                                contentItem: Text {
                                    text: userList[modelData].username
                                    color: focalisWhite
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: addPopupRoot.authUser = modelData
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: px12High
                    //Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: px14High;
                        Layout.alignment: Qt.AlignHCenter
                        Repeater {
                            model: 4;
                            delegate: Rectangle {
                                width: px18High;
                                height: px18High;
                                radius: width/2;
                                color: index < addPopupRoot.currentPinInput.length ? focalisSkyBlue : focalisLightGray
                            }
                        }
                    }
                    GridLayout {
                        columns: 3
                        rowSpacing: px8High
                        columnSpacing: px14High
                        Layout.alignment: Qt.AlignHCenter
                        uniformCellWidths: true
                        Layout.fillWidth: true
                        Repeater {
                            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                            delegate: Button {
                                text: modelData
                                Layout.preferredHeight: 64 / 1080 * appWindow.height
                                Layout.fillWidth: true
                                background: Rectangle {
                                    radius: height / 4
                                    color: focalisLightGray
                                }
                                onClicked: appendPinDigit(modelData) }
                        }
                        Button {
                            text: "Back"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: height / 4
                                color: focalisLightGray
                            }
                            onClicked: addPopupRoot.currentStage = "form"
                        }
                        Button {
                            text: "0"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: height / 4
                                color: focalisLightGray
                            }
                            onClicked: appendPinDigit("0") }
                        Button {
                            text: "⌫"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64 / 1080 * appWindow.height
                            background: Rectangle {
                                radius: height / 4
                                color: focalisLightGray
                            }
                            onClicked: addPopupRoot.currentPinInput = addPopupRoot.currentPinInput.slice(0, -1)
                        }
                    }
                }
            }
        }

        // =========================================================================
        // FLOATING PICKERS (DOCK DIRECTLY TO CONTAINER CONTEXT FRAMES)
        // =========================================================================

        Popup {
            id: startDatePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + startRowContext.x + startDateFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + startRowContext.y + startDateFieldBtn.y + startDateFieldBtn.height + 4
            width: 320 / 1920 * appWindow.width; height: 260 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Button { text: "◀"; flat: true; onClicked: startCalendarMonth = new Date(startCalendarMonth.getFullYear(), startCalendarMonth.getMonth() - 1, 1) }
                    Text { text: startCalendarMonth.toLocaleString(Qt.locale(), "MMMM yyyy"); font.pixelSize: px14High; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Button { text: "▶"; flat: true; onClicked: startCalendarMonth = new Date(startCalendarMonth.getFullYear(), startCalendarMonth.getMonth() + 1, 1) }
                }
                GridLayout {
                    columns: 7; Layout.fillWidth: true; Layout.fillHeight: true; rowSpacing: 2; columnSpacing: 2
                    Repeater { model: ["S","M","T","W","T","F","S"]; delegate: Text { text: modelData; font.pixelSize: px12High; font.bold: true; color: focalisMidGray; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true } }
                    Repeater {
                        model: generateMonthGrid(startCalendarMonth, addPopupRoot.selectedStartDate)
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                            color: modelData.isCurrent ? (modelData.isSelected ? focalisSkyBlue : "transparent") : "transparent"
                            opacity: modelData.isCurrent ? 1.0 : 0.2
                            Text { text: modelData.day; font.pixelSize: px12High; font.bold: modelData.isSelected; color: modelData.isSelected ? focalisWhite : focalisBlack; anchors.centerIn: parent }
                            TapHandler { enabled: modelData.isCurrent; onTapped: { handleStartDateChange(modelData.fullDate); startDatePopup.close() } }
                        }
                    }
                }
            }
        }

        Popup {
            id: endDatePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + endRowContext.x + endDateFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + endRowContext.y + endDateFieldBtn.y + endDateFieldBtn.height + 4
            width: 320 / 1920 * appWindow.width; height: 260 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Button { text: "◀"; flat: true; onClicked: endCalendarMonth = new Date(endCalendarMonth.getFullYear(), endCalendarMonth.getMonth() - 1, 1) }
                    Text { text: endCalendarMonth.toLocaleString(Qt.locale(), "MMMM yyyy"); font.pixelSize: px14High; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                    Button { text: "▶"; flat: true; onClicked: endCalendarMonth = new Date(endCalendarMonth.getFullYear(), endCalendarMonth.getMonth() + 1, 1) }
                }
                GridLayout {
                    columns: 7; Layout.fillWidth: true; Layout.fillHeight: true; rowSpacing: 2; columnSpacing: 2
                    Repeater { model: ["S","M","T","W","T","F","S"]; delegate: Text { text: modelData; font.pixelSize: px12High; font.bold: true; color: focalisMidGray; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true } }
                    Repeater {
                        model: generateMonthGrid(endCalendarMonth, addPopupRoot.selectedEndDate)
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                            color: modelData.isCurrent ? (modelData.isSelected ? focalisSkyBlue : "transparent") : "transparent"
                            opacity: modelData.isCurrent ? 1.0 : 0.2
                            Text { text: modelData.day; font.pixelSize: px12High; font.bold: modelData.isSelected; color: modelData.isSelected ? focalisWhite : focalisBlack; anchors.centerIn: parent }
                            TapHandler { enabled: modelData.isCurrent; onTapped: { handleEndDateChange(modelData.fullDate); endDatePopup.close() } }
                        }
                    }
                }
            }
        }

        Popup {
            id: startTimePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + startRowContext.x + startTimeFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + startRowContext.y + startTimeFieldBtn.y + startTimeFieldBtn.height + 4
            width: 220 / 1920 * appWindow.width; height: 180 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                Tumbler {
                    id: startHourTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [1,2,3,4,5,6,7,8,9,10,11,12]
                    currentIndex: model.indexOf(addPopupRoot.startHour)
                    onCurrentIndexChanged: { addPopupRoot.startHour = model[currentIndex]; enforceTimeValidation() }
                }
                Text { text: ":"; font.bold: true; font.pixelSize: px16High }
                Tumbler {
                    id: startMinTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [0,5,10,15,20,25,30,35,40,45,50,55]
                    currentIndex: model.indexOf(addPopupRoot.startMinute)
                    delegate: Text { text: modelData.toString().padStart(2, '0'); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: px14High; opacity: Tumbler.displacement === 0 ? 1.0 : 0.4 }
                    onCurrentIndexChanged: { addPopupRoot.startMinute = model[currentIndex]; enforceTimeValidation() }
                }
                Tumbler {
                    id: startAmPmTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: ["AM", "PM"]
                    currentIndex: model.indexOf(addPopupRoot.startAmPm)
                    onCurrentIndexChanged: { addPopupRoot.startAmPm = model[currentIndex]; enforceTimeValidation() }
                }
            }
        }

        Popup {
            id: endTimePopup
            x: innerFormContainer.x + mainFormLayout.x + scheduleSection.x + endRowContext.x + endTimeFieldBtn.x
            y: innerFormContainer.y + mainFormLayout.y + scheduleSection.y + endRowContext.y + endTimeFieldBtn.y + endTimeFieldBtn.height + 4
            width: 220 / 1920 * appWindow.width; height: 180 / 1080 * appWindow.height
            modal: false; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            background: Rectangle { radius: px12High; color: focalisWhite; border.color: focalisLightishGray; border.width: 1 }

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                Tumbler {
                    id: endHourTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [1,2,3,4,5,6,7,8,9,10,11,12]
                    currentIndex: model.indexOf(addPopupRoot.endHour)
                    onCurrentIndexChanged: { addPopupRoot.endHour = model[currentIndex]; enforceTimeValidation() }
                }
                Text { text: ":"; font.bold: true; font.pixelSize: px16High }
                Tumbler {
                    id: endMinTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: [0,5,10,15,20,25,30,35,40,45,50,55]
                    currentIndex: model.indexOf(addPopupRoot.endMinute)
                    delegate: Text { text: modelData.toString().padStart(2, '0'); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: px14High; opacity: Tumbler.displacement === 0 ? 1.0 : 0.4 }
                    onCurrentIndexChanged: { addPopupRoot.endMinute = model[currentIndex]; enforceTimeValidation() }
                }
                Tumbler {
                    id: endAmPmTumbler; Layout.fillWidth: true; Layout.fillHeight: true; model: ["AM", "PM"]
                    currentIndex: model.indexOf(addPopupRoot.endAmPm)
                    onCurrentIndexChanged: { addPopupRoot.endAmPm = model[currentIndex]; enforceTimeValidation() }
                }
            }
        }
    }

    // =========================================================================
    // CALENDAR GRID GENERATION HELPER
    // =========================================================================
    function generateMonthGrid(monthStartDate, currentSelectedDate) {
        var year = monthStartDate.getFullYear()
        var month = monthStartDate.getMonth()
        var firstDayIndex = new Date(year, month, 1).getDay()
        var totalDays = new Date(year, month + 1, 0).getDate()

        var gridCells = []
        for (var i = 0; i < firstDayIndex; i++) {
            gridCells.push({ "day": "", "isCurrent": false, "isSelected": false, "fullDate": new Date() })
        }
        for (var day = 1; day <= totalDays; day++) {
            var cellDate = new Date(year, month, day)
            var isSelected = (cellDate.getDate() === currentSelectedDate.getDate() &&
                              cellDate.getMonth() === currentSelectedDate.getMonth() &&
                              cellDate.getFullYear() === currentSelectedDate.getFullYear())
            gridCells.push({ "day": day.toString(), "isCurrent": true, "isSelected": isSelected, "fullDate": cellDate })
        }
        return gridCells
    }

    ParallelAnimation {
        id: popupOpenAnimate; running: false
        NumberAnimation { target: centralContainer; property: "scale"; from: 0; to: 1; duration: 180; easing.type: Easing.OutBack }
        NumberAnimation { target: addEventBackground; property: "opacity"; from: 0; to: 1; duration: 180 }
        onRunningChanged: { if (running) addPopupRoot.visible = true }
    }
    ParallelAnimation {
        id: popupCloseAnimate; running: false
        NumberAnimation { target: centralContainer; property: "scale"; from: 1; to: 0; duration: 150 }
        NumberAnimation { target: addEventBackground; property: "opacity"; from: 1; to: 0; duration: 150 }
        onRunningChanged: { if (!running) addPopupRoot.visible = false }
    }
}
*/