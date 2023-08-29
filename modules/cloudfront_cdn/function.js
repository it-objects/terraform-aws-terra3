function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/admin-terra3/')) {
        request.uri += 'index.html';
    }

    return request;
}
