function register(baseUrl) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            if (xhttp.responseText) {
                // A session will be returned if email verification is not required.
                const newSession = JSON.parse(xhttp.responseText);
                const user = newSession.user;
                if (newSession.token) {
                    window.localStorage.setItem('id', newSession.id);
                    window.localStorage.setItem('token', newSession.token);
                    window.localStorage.setObject('user', newSession.user);
                    window.location = baseUrl + "/view/home";
                }
            } else { 
                // Otherwise the user should be prompted to verify their email.
                alert("An email was sent to " + document.getElementById('email-input').value + " for email verification. You must verify your email before you can login.");
            }
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    var body = getBody();
    if (body) {
        xhttp.open("POST", baseUrl + "/auth/register");
        xhttp.send(body);
    }
}

function getBody() {
    var firstName = document.getElementById('first-name-input').value;
    var lastName = document.getElementById('last-name-input').value;
    var email = document.getElementById('email-input').value;
    var password = document.getElementById('password-input').value;
    var verifyPassword = document.getElementById('verify-password-input').value;
    if (password.length == 0 || verifyPassword.length == 0) {
        alert("Invalid new password and/or verification.");
        return null;
    }
    if (password != verifyPassword) {
        alert("Passwords don't match.");
        return null;
    }
    var body = new FormData();
    body.set('firstName', firstName);
    body.set('lastName', lastName);
    body.set('email', email);
    body.set('password', password);
    return body;
}
