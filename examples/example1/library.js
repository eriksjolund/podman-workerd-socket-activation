// parse field clientIp
//
// For example the input
// "[::ffff:127.0.0.1]:50974"
// should result in "127.0.0.1"
function parseClientIp(clientIp) {
  if (clientIp.startsWith("[::ffff:")) {
    const splits = clientIp.substring(8).split("]", 2);
    if (splits.length == 2) {
      return splits[0];
    }
  }
  return null;
}

// Create request with proxy headers
export function createProxyRequest(req) {
  const url = new URL(req.url);
  const req2 = new Request(url, req);
  const ip = parseClientIp(req.cf.clientIp);
  if (ip) {
    req2.headers.append('X-Forwarded-For', ip);
  }
  req2.headers.append('X-Forwarded-Host', url.hostname);
  return req2;
}

