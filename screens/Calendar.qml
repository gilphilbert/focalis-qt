import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../components" as Components

Rectangle {


    anchors.fill: parent

    id: calendarRoot
    property var calendars: []
    property var rawEvents: []
    property var events: []
    property int daysShown: 5

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: function() {
            sendRequest('http://localhost:8080/calendarevents', function (o) {
                calendars = JSON.parse(o.content)
            })
        }
    }

    function sendRequest(url, callback) {
        let request = new XMLHttpRequest();

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                let response = {
                    status : request.status,
                    headers : request.getAllResponseHeaders(),
                    contentType : request.responseType,
                    content : request.response
                };

                callback(response);
            }
        }

        request.open("GET", url);
        request.send();
    }

    // --------------------- title and weather --------------------- //
    ColumnLayout {
        width: parent.width
        spacing: 40
        Layout.topMargin: 15

        RowLayout {
            width: parent.width
            Layout.leftMargin: 10
            Layout.rightMargin: 10

            Text {
                text: "The Gilberts"
                font.pixelSize: 50
                topPadding: 20
                bottomPadding: topPadding
                leftPadding: 20
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Row {
                Layout.fillHeight: true

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                            source: "https://cdn.search.brave.com/serp/v3/_app/immutable/assets/04d.Y1QwzDKO.svg"
                            height: 50
                            width: 50
                            fillMode: Image.PreserveAspectFit
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "57°F"
                        font.pixelSize: 20
                        rightPadding: 20
                    }
                }
            }

        }

        // --------------------- user row --------------------- //
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10

            Repeater {
                model: calendarRoot.calendars
                Components.NameTag {
                    required property var modelData
                    name: modelData.DisplayName
                    tagColor: modelData.Color
                }
            }
        }

        // --------------------- agenda --------------------- //
        RowLayout {
            width: parent.width
            Layout.fillHeight: true
            uniformCellSizes: true
            spacing: 10
            Layout.leftMargin: 10
            Layout.rightMargin: 10

            Repeater {
                model: calendarRoot.events //calendarItems(5)

                Rectangle {
                    id: dayColumn
                    required property var modelData

                    Layout.fillWidth: true
                    height: 20
                    Column {
                        width: parent.width
                        spacing: 3
                        Text {
                            text: dayColumn.modelData.prettyDate //dayColumn.modelData.prettyDate
                            font.weight: 500
                            font.pixelSize: 20
                            bottomPadding: 3
                        }
                        Text {
                            text: (dayColumn.modelData.entries.length || "no") + " event" + ((dayColumn.modelData.entries.length !== 1) ? "s" : "")
                            font.weight: 400
                            font.pixelSize: 20
                            bottomPadding: 10
                            opacity: 0.7
                        }

                        Repeater {
                            model: dayColumn.modelData.entries

                            Rectangle {
                                id: entryRect
                                required property var modelData
                                property string itemColor: calendarRoot.calendars.find(cal => cal.URL === entryRect.modelData.calID).Color.substr(0, 7)

                                visible: modelData.show

                                property int fontSizePx: 20
                                property int spacing: 14
                                width: parent.width
                                height: childrenRect.height
                                color: itemColor
                                radius: 12

                                Column {
                                    spacing: 2
                                    padding: 10
                                    width: parent.width
                                    Text {
                                        width: parent.width - (parent.padding * 2)
                                        text: entryRect.modelData.Summary
                                        color: shadeColor(itemColor, -60)
                                        font.pixelSize: parent.parent.fontSizePx
                                        clip: true
                                        font.weight: 600
                                    }
                                    Text {
                                        width: parent.width - (parent.padding * 2)
                                        text: entryRect.modelData.prettyTime
                                        color: shadeColor(itemColor, -60)
                                        font.pixelSize: parent.parent.fontSizePx
                                        clip: true
                                    }
                                }
                            }

                        }
                    }
                }
            }
        }
    }

    // --------------------- functions --------------------- //

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

    onCalendarsChanged: function() {
        //need to check if an event already exists and skip it!

        let obj = [];
        calendars.forEach(cal => {
            //cal.events.forEach(evt => {
            //    obj.push(evt.map)
            //})
            obj = obj.concat(cal.Events.map(e => { e.calID = cal.URL; return e }))
        })
        //console.info(JSON.stringify(obj))
        let retVal = []

        for (let i = 0; i < daysShown; i++) {
            let arr = []

            // need to change this to get the timestamp in x days
            const iDaysAway = new Date()
            iDaysAway.setDate(iDaysAway.getDate() + i)

            arr = obj.filter(entry => {
                const _d = new Date()
                _d.setTime(entry.Start * 1000)

                return _d.getDate() === iDaysAway.getDate() && _d.getMonth() === iDaysAway.getMonth()
            })

            arr.sort(( a, b ) => {
                if ( a.Start < b.Start ){
                    return -1;
                }
                if ( a.Start > b.Start ){
                    return 1;
                }
                return 0;
            })

            arr.forEach(entry => {
                const _start = new Date();
                _start.setTime(entry['Start'] * 1000)

                const _end = new Date();
                _end.setTime(entry['End'] * 1000)

                let fStart = (_start.getHours() > 12 ? _start.getHours() - 12 : _start.getHours()) + ":" +  (_start.getMinutes() < 10 ? "0" + _start.getMinutes() : _start.getMinutes())
                let fEnd =(_end.getHours() > 12 ? _end.getHours() - 12 : _end.getHours()) + ":" +  (_end.getMinutes() < 10 ? "0" + _end.getMinutes() : _end.getMinutes()) + (_end.getHours() >= 12 ? " PM" : " AM")

                entry['prettyTime'] = entry['allDay'] ? "All Day" : fStart + " - " + fEnd

                entry['show'] = true
            })

            const dow = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

            retVal.push({ prettyDate: dow[iDaysAway.getDay()] + " " + iDaysAway.getDate(), entries: arr })
        }

        events = retVal

        //console.info(JSON.stringify(events))
    }

}
