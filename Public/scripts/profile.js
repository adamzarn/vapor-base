document.addEventListener('DOMContentLoaded', function() {
    const url = window.location.toString();
    const userId = url.substring(url.lastIndexOf('/') + 1);
    const user = window.localStorage.getObject('user');
    if (user == null) { return }
    if (userId != user.id) { return }
    document.getElementById("change-password-button").style.display = "inline-block";
}, false);

function changePassword() {
    const tokenId = window.localStorage.getItem('id');
    if (tokenId) {  
        window.location = getBaseUrl() + "/view/passwordReset/" + tokenId;
    }
}
