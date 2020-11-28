Storage.prototype.setObject = function(key, value) {
    this.setItem(key, JSON.stringify(value));
}

Storage.prototype.getObject = function(key) {
    return JSON.parse(this.getItem(key));
}

function showResponseAlert(xhttp) {
    if (xhttp.responseText) {
        const response = JSON.parse(xhttp.responseText);
        alert(response.reason);
    }
}

function getBaseUrl() {
    const loc = window.location;
    const scheme = loc.protocol;
    const host = loc.hostname;
    const port = loc.port;
    return scheme + "//" + host + ":" + port;
}

function onMouseOverUser(row) {
    row.bgColor = 'orange'
    row.style.color = 'white'
    row.style.cursor = 'pointer'
}

function onMouseOutUser(row) {
    row.bgColor='white'
    row.style.color='black'
    row.style.cursor='auto'
}

function home() {
    window.location = getBaseUrl() + "/view/home";
}

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
            endSession();
            window.location = getBaseUrl() + "/view/welcome";
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("DELETE", getBaseUrl() + "/auth/logout");
    xhttp.setRequestHeader("Authorization", getBearerAuthorizationValue());
    xhttp.send();
}

function getBearerAuthorizationValue() {
    return "Bearer " + window.localStorage.getItem('token');
}

function endSession() {
    window.localStorage.removeItem('id');
    window.localStorage.removeItem('token');
    window.localStorage.removeItem('user');
}

function loggedInUserId() {
    const user = window.localStorage.getObject('user');
    return user.id;
}