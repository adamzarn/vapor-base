function resetPassword(baseUrl, passwordResetUrl) {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            const token = window.localStorage.getItem('token');
            let message = "Your password was successfully reset.";
            if (token) {
                alert(message);
            } else {
                message += " You will now be redirected to the login page.";
                alert(message);
                window.location = baseUrl + "/view/login";
            }
        } else if (this.readyState == 4) {    
            showResponseAlert(xhttp);
        }
    };
    var body = getBody();
    if (body) {
        xhttp.open("PUT", passwordResetUrl);
        xhttp.send(body);
    }
}

function getBody() {
    var password = document.getElementById('password-input').value;
    var verifyPassword = document.getElementById('verify-password-input').value;
    if (password.length == 0 || verifyPassword.length == 0) {
        console.log('here');
        alert("Invalid new password and/or verification.");
        return null;
    }
    if (password != verifyPassword) {
        console.log('there');
        alert("Passwords don't match.");
        return null;
    }
    console.log('everywhere');
    var body = new FormData();
    body.set('value', password);
    return body;
}
