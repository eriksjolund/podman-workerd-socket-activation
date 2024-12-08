import { createProxyRequest } from "library";

export default {
  async fetch(req, env, ctx) {
    // console.log("%o", req);
    const req2 = createProxyRequest(req);
    return await fetch(req2, env, ctx);
  }
}
