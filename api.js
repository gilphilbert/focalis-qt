// api.js
.pragma library

// A clean, generic wrapper for making secure POST requests
function postSecureAction(url, payload, adultId, pin, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/json");

    // Pass the active validation headers your Gin middleware is expecting
    xhr.setRequestHeader("X-Target-Adult-ID", adultId);
    xhr.setRequestHeader("X-Adult-PIN", pin);

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 201) {
                var response = JSON.parse(xhr.responseText);
                callback(null, response);
            } else {
                // Parse out the Gin JSON error message if available
                var errRes = xhr.responseText ? JSON.parse(xhr.responseText) : {};
                callback(errRes.error || "Action failed with status: " + xhr.status);
            }
        }
    };

    xhr.send(JSON.stringify(payload));
}

/*
  sample usage:

import QtQuick 2.15
import QtQuick.Controls 2.15
import "api.js" as Api

Item {
    id: choreRoot
    width: 400
    height: 300

    // Properties tracking state on your shared screen
    property string selectedAdultId: "user-uuid-1234" // Selected parent icon
    property string temporaryPinInput: "1234"         // Collected from a keypad component

    Button {
        id: approveButton
        text: "Approve Chore"
        anchors.centerIn: parent

        onClicked: {
            // Assemble the endpoint payload
            var payload = {
                "status": true
            };

            // Construct your dynamic Gin URL route
            var targetUrl = "http://localhost:8080/api/users/" + selectedAdultId;

            // Execute the network request using our helper
            Api.postSecureAction(targetUrl, payload, selectedAdultId, temporaryPinInput, function(error, result) {
                if (error) {
                    console.log("Authorization Failed: " + error);
                    // Pop up an error toast on the UI: "Invalid PIN"
                } else {
                    console.log("Success! Server returned updated records.");
                    // Flush the temporary PIN field and close the popup window immediately
                    temporaryPinInput = "";
                }
            });
        }
    }
}

*/