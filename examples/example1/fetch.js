import { createProxyRequest } from "library";

export default {
  async fetch(req, env, ctx) {
    // console.log("%o", req);
    const url = new URL(req.url);
    const req2 = createProxyRequest(req);
    if (url.hostname == "whoami.example.com"){
      return await env.whoami_binding.fetch(req2, env, ctx);
    } else {
      return new Response("Not found", {status: 404});
    }
  }
}
