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

function onMouseOverUser(row) {
    row.bgColor = 'orange'
    row.style.color = 'white'
    row.style.cursor = 'pointer'
}

function onMouseOutUser(row) {
    row.bgColor='white'
    row.style.color='black'
    row.style.cursor='auto'
}

class UserTableHeader extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = `
        <div>
            <tr>
                <td><b>Name</b></td>
                <td><b>Email</b></td>
            </tr>
        </div>
        `;
    }
}
customElements.define('user-table-th', UserTableHeader)