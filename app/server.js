// A zero-dependency server for the example sign-in page.
// Run it with `npm start` and open http://127.0.0.1:8080/sign-in
const http = require("node:http");
const fs = require("node:fs/promises");
const path = require("node:path");

const port = Number(process.env.PORT) || 8080;

// Paths the scenarios can visit, mapped to the file that serves them.
const pages = {
  "/sign-in": "sign-in.html",
};

// Static files (fonts) live under app/assets and are served from /assets.
const assetsDir = path.join(__dirname, "assets");
const assetTypes = {
  ".woff2": "font/woff2",
  ".svg": "image/svg+xml",
  ".css": "text/css; charset=utf-8",
};

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, `http://localhost:${port}`);

  if (pathname === "/") {
    res.writeHead(302, { Location: "/sign-in" });
    res.end();
    return;
  }

  if (pathname.startsWith("/assets/")) {
    const filePath = path.join(assetsDir, pathname.slice("/assets/".length));
    const type = assetTypes[path.extname(filePath)];
    // Refuse anything that escapes the assets folder or isn't a known type.
    if (!filePath.startsWith(assetsDir + path.sep) || !type) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Not found");
      return;
    }
    try {
      const body = await fs.readFile(filePath);
      res.writeHead(200, {
        "Content-Type": type,
        "Cache-Control": "public, max-age=31536000, immutable",
      });
      res.end(body);
    } catch {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Not found");
    }
    return;
  }

  // Serve GET and POST the same way, so submitting the form without
  // JavaScript just shows the page again rather than a 404.
  const file = pages[pathname.replace(/\/+$/, "")];
  if (!file) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("Not found");
    return;
  }

  const html = await fs.readFile(path.join(__dirname, file));
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(html);
});

server.listen(port, () => {
  console.log(`Example app running at http://127.0.0.1:${port}/sign-in`);
});
