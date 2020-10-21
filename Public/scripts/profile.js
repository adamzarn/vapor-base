document.addEventListener('DOMContentLoaded', function() {
    const url = window.location.toString();
    const userId = url.substring(url.lastIndexOf('/') + 1);
    const user = window.localStorage.getObject('user');
    if (user == null) { return }
    if (userId != user.id) { return }
    document.getElementById("change-password-button").style.display = "inline-block";
}, false);

function changePassword(baseUrl) {
    console.log(baseUrl);
    const tokenId = window.localStorage.getItem('id');
    console.log(tokenId);
    if (tokenId) {  
        window.location = baseUrl + "/view/passwordReset/" + tokenId;
    }
}