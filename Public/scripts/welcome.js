document.addEventListener('DOMContentLoaded', function() {
    if (window.localStorage.getItem('token')) {
        window.location = getBaseUrl() + "/view/home";
    }
}, false);

function register() {
    window.location = getBaseUrl() + "/view/register";
}

function login() {
    window.location = getBaseUrl() + "/view/login";
}
