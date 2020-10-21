document.addEventListener('DOMContentLoaded', function() {
    updateView()
}, false);

function register(baseUrl) {
    window.location = baseUrl + "/view/register";
}

function login(baseUrl) {
    window.location = baseUrl + "/view/login";
}

function profile(baseUrl) {
    const user = window.localStorage.getObject('user');
    if (user) {
        window.location = baseUrl + "/view/profile/" + user.id;
    }
}

function logout(baseUrl) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            window.localStorage.removeItem('id');
            window.localStorage.removeItem('token');
            window.localStorage.removeItem('user');
            updateView()
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("DELETE", baseUrl + "/auth/logout");
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
        document.getElementById("register-button").style.display = "none";
        document.getElementById("login-button").style.display = "none";
        document.getElementById("profile-button").style.display = "inline-block";
        document.getElementById("logout-button").style.display = "inline-block";
    } else {
        document.getElementById("welcome").innerHTML = "Hello!";
        document.getElementById("register-button").style.display = "inline-block";
        document.getElementById("login-button").style.display = "inline-block";
        document.getElementById("profile-button").style.display = "none";
        document.getElementById("logout-button").style.display = "none";
    }
}
