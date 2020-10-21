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