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
