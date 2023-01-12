const https = require('https')

exports.handler = async function(event) {
  console.log(JSON.stringify(event));
  let url = event.url;
  let httpVerb = event.httpVerb;
  const promise = new Promise(function(resolve, reject) {
    https.get(url, (res) => {
        resolve(res.statusCode)
      }).on('error', (e) => {
        reject(Error(e))
      })
    })
  return promise
}
