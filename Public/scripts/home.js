document.addEventListener('DOMContentLoaded', function() {
    updateView();
}, false);

function profile() {
    const user = window.localStorage.getObject('user');
    if (user) {
        navigateToUserProfile(user.id);
    }
}

function logout() {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            window.localStorage.removeItem('id');
            window.localStorage.removeItem('token');
            window.localStorage.removeItem('user');
            updateView();
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("DELETE", getBaseUrl() + "/auth/logout");
    xhttp.setRequestHeader("Authorization", getAuthorizationValue());
    xhttp.send();
}

function getAuthorizationValue() {
    return "Bearer " + window.localStorage.getItem('token');
}

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
