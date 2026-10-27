"use strict";

if (process.env.MKDP_RELOAD_FIX === "1") {
  const fs = require("node:fs");
  const http = require("node:http");
  const createServer = http.createServer;

  http.createServer = function (...args) {
    const listenerIndex = typeof args[0] === "function" ? 0 : 1;
    const listener = args[listenerIndex];

    if (typeof listener === "function") {
      args[listenerIndex] = function (request, response) {
        const url = request.url || "";
        const pathname = url.replace(/[?#].*$/, "");

        if (pathname === "/_static/mermaid.min.js" && process.env.MKDP_MERMAID_ASSET) {
          const asset = fs.createReadStream(process.env.MKDP_MERMAID_ASSET);
          asset.on("error", (error) => {
            if (response.headersSent) {
              response.destroy(error);
              return;
            }
            response.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
            response.end(`Could not load Mermaid: ${error.message}`);
          });
          response.setHeader("Content-Type", "application/javascript; charset=utf-8");
          asset.pipe(response);
          return;
        }

        if (/^\/\d+$/.test(pathname)) {
          response.writeHead(302, { Location: `/page${url}` });
          response.end();
          return;
        }

        return listener.call(this, request, response);
      };
    }

    return createServer.apply(this, args);
  };
}
