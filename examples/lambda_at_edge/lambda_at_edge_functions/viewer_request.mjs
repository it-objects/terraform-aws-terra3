import * as path from 'path';

export const handler = async (event, context, callback) => {
  const { request } = event.Records[0].cf;
  const parsedPath = path.parse(request.uri);

  // Check if the URI path does not specify a file extension
  if (parsedPath.ext === '') {
    // Redirect /admin/* to /admin/index.html, excluding /admin/index.html itself
    if (request.uri.startsWith('/admin/') && !request.uri.endsWith('index.html')) {
      request.uri = '/admin/index.html';
    }
    // Redirect all other paths without a file extension to /index.html
    else if (!request.uri.startsWith('/admin/')) {
      request.uri = '/index.html';
    }
  }

  console.log("REQUEST_URI" + request.uri);

  callback(null, request);
};
