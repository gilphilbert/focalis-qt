import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: boardRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Signals out to Go backend via your bridge API
    signal choreStatusChanged(string id)

    // Bind this to your Go-populated array or list model
    property alias choreModel: choreGridView.model

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 24

        // Board Header Banner
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 4
                Text {
                    text: "Today's Work Checklist"
                    font.pixelSize: 32
                    //font.weight: Font.Bold
                    color: "#0F172A"
                }
                Text {
                    text: "Tap your card to complete a chore and unlock points!"
                    font.pixelSize: 18
                    color: "#64748B"
                }
            }
        }

        // Responsive Scroll Grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            GridView {
                id: choreGridView
                width: parent.width
                height: contentHeight
                cellWidth: 360   // Roomy target spacing for large monitors
                cellHeight: 200
                flow: GridView.FlowLeftToRight
                clip: true

                delegate: ChoreCard {
                    // Inject database fields straight to the structural card handles
                    choreId: model.id
                    title: model.title
                    assignedTo: model.assignedTo
                    points: model.points
                    status: model.status

                    // Catch card click events and bubbles up to global handlers
                    onChoreToggled: function(id) {
                        boardRoot.choreStatusChanged(id)
                    }
                }
            }
        }
    }
}