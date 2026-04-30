import * as path from 'path';

export const handler = async (event) => {
  const { request } = event.Records[0].cf;
  const parsedPath = path.parse(request.uri);

  if (parsedPath.ext === '') {
      request.uri = '/index.html';
  }

  console.log("REQUEST_URI" + request.uri);

  return request;
};
