$(document).ready(function() {
    function getLocation() {
        navigator.geolocation.getCurrentPosition(sendPosition, onError, {timeout: 10000});
    }

    function sendPosition(position) {
        var latitude = position.coords.latitude;
        var longitude = position.coords.longitude;

        coords = `${latitude},${longitude}`;

        $.getJSON(location.origin + `/location?lat=${latitude}&long=${longitude}`, function(json) {
            if (json.error) {
                document.getElementById("loading-status").innerHTML = json.error.message;
                setTimeout(function() {
                    // Redirect user to the home page
                    window.location.replace(window.location.origin);
                }, 2000);
            } else {
                // Redirect user to the home page
                window.location.replace(window.location.origin);
            }
        });
    }

    function onError(error) {
        console.log(error);

        var error_message = "";
        if (error.code == error.PERMISSION_DENIED) {
            error_message = "Location access denied";
        } else if (error.code == 2) {
            error_message = error.message;
        }
        document.getElementById("loading-status").innerHTML = error_message;

        setTimeout(function() {
            // Redirect user to the home page
            window.location.replace(window.location.origin);
        }, 2000);
    }
    
    getLocation();
});
