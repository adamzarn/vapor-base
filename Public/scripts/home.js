document.addEventListener('DOMContentLoaded', function() {
    updateView();
}, false);

function updateView() {
    if (window.localStorage.getItem('token')) {
        const user = window.localStorage.getObject('user');
        document.getElementById("welcome").innerHTML = "Hello " + user.firstName + " " + user.lastName + "!";
    } else {
        window.location = getBaseUrl() + "/view/welcome";
    }
}

function navigateToUserProfile(id) {
    console.log(id);
    window.location = getBaseUrl() + "/view/profile/" + id;
}

function deleteUser(event, id) {
    event.stopPropagation();
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            if (id === loggedInUserId()) {
                endSession();
            }
            window.location.reload();
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("DELETE", getBaseUrl() + "/users/" + id);
    xhttp.setRequestHeader("Authorization", getBearerAuthorizationValue());
    xhttp.send();
}

function setAdminStatus(event, id, isAdmin) {
    event.stopPropagation();
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            window.location.reload();
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("PUT", getBaseUrl() + "/users/" + id + "/setAdminStatus");
    xhttp.setRequestHeader("Authorization", getBearerAuthorizationValue());
    var body = new FormData();
    body.set('isAdmin', isAdmin);
    xhttp.send(body);
}


