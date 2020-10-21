function login(baseUrl) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            const newSession = JSON.parse(xhttp.responseText);
            window.localStorage.setItem('id', newSession.id);
            window.localStorage.setItem('token', newSession.token);
            window.localStorage.setObject('user', newSession.user);
            window.location = baseUrl + "/view/home"
        } else if (this.readyState == 4 && this.status == 403) {
            var message = "You were successfully authenticated but your email is not yet verified. Should we resend the email verification email?"
            var confirmed = window.confirm(message);
            if (confirmed) {
                resendEmailVerificationEmail(baseUrl);
            }
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("POST", baseUrl + "/auth/login");
    xhttp.setRequestHeader("Authorization", getAuthorizationValue());
    xhttp.send();
}

function resendEmailVerificationEmail(baseUrl) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            alert("An email was sent to " + document.getElementById("email-input").value
            + " for email verification.")
            resendEmailVerificationEmailAlreadyAttempted = true;
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("POST", baseUrl + "/auth/sendEmailVerificationEmail");
    xhttp.setRequestHeader("Authorization", getAuthorizationValue());
    xhttp.send();
}

function getAuthorizationValue() {
    var email = document.getElementById("email-input").value
    var password = document.getElementById("password-input").value
    var base64Encoded = btoa(email + ":" + password);
    return "Basic " + base64Encoded
}

function sendPasswordResetEmail(baseUrl, email) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            alert("An email was sent to " + email + " for password reset.")
        } else if (this.readyState == 4) {    
            showResponseAlert(xhttp);
        }
    };
    xhttp.open("POST", baseUrl + "/auth/sendPasswordResetEmail/" + document.getElementById("email-input").value);
    xhttp.send();
}

function forgotPassword(baseUrl) {
    var email = document.getElementById("email-input").value
    if (email.length === 0) {
        alert("Please enter the email you'd like a password reset email to be sent to.");
        return;
    }
    var message = "Would you like us to send a password reset email to " + email + "?";
    var confirmed = window.confirm(message);
    if (confirmed) {
        sendPasswordResetEmail(baseUrl, email);
    }
}
