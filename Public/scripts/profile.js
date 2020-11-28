document.addEventListener('DOMContentLoaded', function() {
    if (currentUserId() == null) { return }
    if (currentUserId() != loggedInUserId()) { return }
    document.getElementById("change-password-button").style.display = "inline-block";
    document.getElementById("following-button").style.display = "none";
}, false);

function changePassword() {
    const tokenId = window.localStorage.getItem('id');
    if (tokenId) {  
        window.location = getBaseUrl() + "/view/passwordReset/" + tokenId;
    }
}

function navigateToUserProfile(id) {
    window.location = getBaseUrl() + "/view/profile/" + id;
}

function toggleFollowingStatus(followerIds, followers) {
    console.log(followers);
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            window.location.reload();
        } else if (this.readyState == 4) {
            showResponseAlert(xhttp);
        }
    };
    const url = getBaseUrl() + "/users/" + loggedInUserId() + "/setFollowingStatus";
    xhttp.open("POST", getBaseUrl() + "/users/" + loggedInUserId() + "/setFollowingStatus");
    xhttp.setRequestHeader("Authorization", getBearerAuthorizationValue());
    var body = new FormData();
    body.set('otherUserId', currentUserId());
    body.set('follow', !alreadyFollowing(followerIds));
    xhttp.send(body);
}

function setFollowingStatus(followerIds) {
    let followingButton = document.getElementById("following-button");
    followingButton.innerHTML = alreadyFollowing(followerIds) ? "Unfollow" : "Follow";
}

function alreadyFollowing(followerIds) {
    return followerIds.includes(loggedInUserId());
}

function currentUserId() {
    const url = window.location.toString();
    return url.substring(url.lastIndexOf('/') + 1);
}