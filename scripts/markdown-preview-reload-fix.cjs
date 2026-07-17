"use strict";

if (process.env.MKDP_RELOAD_FIX === "1") {
  const http = require("node:http");
  const createServer = http.createServer;

  http.createServer = function (...args) {
    const listenerIndex = typeof args[0] === "function" ? 0 : 1;
    const listener = args[listenerIndex];

    if (typeof listener === "function") {
      args[listenerIndex] = function (request, response) {
        const url = request.url || "";
        const pathname = url.replace(/[?#].*$/, "");

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
