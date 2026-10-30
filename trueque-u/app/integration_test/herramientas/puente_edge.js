const http = require("http");
http.createServer((req, res) => {
  const partes = [];
  req.on("data", (d) => partes.push(d));
  req.on("end", () => {
    let cuerpo = Buffer.concat(partes);
    if (req.method === "POST" && req.url === "/session") {
      const o = JSON.parse(cuerpo.toString());
      const lista = [o.desiredCapabilities, o.capabilities && o.capabilities.alwaysMatch].filter(Boolean);
      for (const c of lista) {
        c.browserName = "MicrosoftEdge";
        if (c["goog:chromeOptions"]) {
          c["ms:edgeOptions"] = c["goog:chromeOptions"];
          delete c["goog:chromeOptions"];
          delete c["ms:edgeOptions"].perfLoggingPrefs;
          delete c["goog:loggingPrefs"];
        }
      }
      cuerpo = Buffer.from(JSON.stringify(o));
      console.log(cuerpo.toString());
    }
    const headers = { ...req.headers, "content-length": cuerpo.length };
    const p = http.request({ host: "127.0.0.1", port: 4445, path: req.url, method: req.method, headers }, (r) => {
      res.writeHead(r.statusCode, r.headers);
      r.pipe(res);
    });
    p.on("error", (e) => { res.writeHead(500); res.end(String(e)); });
    p.end(cuerpo);
  });
}).listen(4444);
