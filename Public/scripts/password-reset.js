function resetPassword(tokenId) {
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
                window.location = getBaseUrl() + "/view/login";
            }
        } else if (this.readyState == 4) {    
            showResponseAlert(xhttp);
        }
    };
    var body = getBody();
    if (body) {
        xhttp.open("PUT", getBaseUrl() + "/auth/resetPassword/" + tokenId);
        xhttp.send(body);
    }
}

function getBody() {
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
    body.set('value', password);
    return body;
}
