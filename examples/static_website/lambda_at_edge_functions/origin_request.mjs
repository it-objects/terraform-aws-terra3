import * as path from 'path';

export const handler = async (event, context, callback) => {
  const { request } = event.Records[0].cf;
  const parsedPath = path.parse(request.uri);

  // Check if the URI path does not specify a file extension
  if (parsedPath.ext === '') {
      request.uri = '/index.html';
  }

  console.log("REQUEST_URI" + request.uri);

  callback(null, request);
};
