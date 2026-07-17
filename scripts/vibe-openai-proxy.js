#!/usr/bin/env node

const http = require("node:http");
const { URL } = require("node:url");

const hopByHopHeaders = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

function parseArgs(argv) {
  const args = {
    bind: "127.0.0.1",
    port: 18025,
    upstreamBase: "",
    timeout: 720_000,
    selfTest: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg) {
      case "--bind":
        args.bind = argv[++index];
        break;
      case "--port":
        args.port = Number(argv[++index]);
        break;
      case "--upstream-base":
        args.upstreamBase = argv[++index];
        break;
      case "--timeout":
        args.timeout = Number(argv[++index]) * 1000;
        break;
      case "--self-test":
        args.selfTest = true;
        break;
      case "-h":
      case "--help":
        printHelp();
        process.exit(0);
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Usage: vibe-openai-proxy.js [options]

Options:
  --bind HOST             Address to bind (default: 127.0.0.1)
  --port PORT             Port to bind (default: 18025)
  --upstream-base URL     Upstream OpenAI base URL, usually http://host:port/v1
  --timeout SECONDS       Upstream timeout (default: 720)
  --self-test             Run normalization tests and exit
`);
}

function combineContent(left, right) {
  if (left === undefined || left === null || left === "") return right;
  if (right === undefined || right === null || right === "") return left;

  if (typeof left === "string" && typeof right === "string") {
    return `${left}\n\n${right}`;
  }

  const parts = [];
  if (Array.isArray(left)) {
    parts.push(...left);
  } else {
    parts.push({ type: "text", text: String(left) });
  }

  parts.push({ type: "text", text: "\n\n" });

  if (Array.isArray(right)) {
    parts.push(...right);
  } else {
    parts.push({ type: "text", text: String(right) });
  }

  return parts;
}

function mergeable(role, previous, current) {
  if (role !== "system" && role !== "user") return false;
  return !previous.tool_calls && !current.tool_calls;
}

function normalizeMessages(messages) {
  if (!Array.isArray(messages)) return messages;

  const normalized = [];
  for (const message of messages) {
    if (!message || typeof message !== "object" || Array.isArray(message)) {
      normalized.push(message);
      continue;
    }

    const role = message.role;
    const previous = normalized[normalized.length - 1];
    if (previous && previous.role === "tool" && role === "user") {
      normalized.push({ role: "assistant", content: "" });
    }

    const mergeTarget = normalized[normalized.length - 1];
    if (
      mergeTarget &&
      mergeTarget.role === role &&
      typeof role === "string" &&
      mergeable(role, mergeTarget, message)
    ) {
      normalized[normalized.length - 1] = {
        ...message,
        ...mergeTarget,
        content: combineContent(mergeTarget.content, message.content),
      };
      continue;
    }

    normalized.push(message);
  }

  return normalized;
}

function normalizePayload(body) {
  if (!body.length) return body;

  let payload;
  try {
    payload = JSON.parse(body.toString("utf8"));
  } catch {
    return body;
  }

  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    return body;
  }

  if (!Object.prototype.hasOwnProperty.call(payload, "messages")) {
    return body;
  }

  return Buffer.from(
    JSON.stringify({ ...payload, messages: normalizeMessages(payload.messages) }),
    "utf8",
  );
}

function selfTest() {
  const payload = {
    messages: [
      { role: "system", content: "s1" },
      { role: "user", content: "compacted" },
      { role: "user", content: "next" },
      {
        role: "assistant",
        content: "",
        tool_calls: [{ id: "1", function: { name: "read_file" } }],
      },
      { role: "tool", tool_call_id: "1", content: "ok" },
      { role: "user", content: "compact now" },
    ],
  };
  const normalized = JSON.parse(normalizePayload(Buffer.from(JSON.stringify(payload))));
  const roles = normalized.messages.map((message) => message.role);
  const expected = ["system", "user", "assistant", "tool", "assistant", "user"];
  if (JSON.stringify(roles) !== JSON.stringify(expected)) {
    throw new Error(`Unexpected roles: ${JSON.stringify(roles)}`);
  }
  if (normalized.messages[1].content !== "compacted\n\nnext") {
    throw new Error("Consecutive user messages were not merged");
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function filteredHeaders(headers, bodyLength) {
  const result = {};
  for (const [key, value] of Object.entries(headers)) {
    const lower = key.toLowerCase();
    if (hopByHopHeaders.has(lower) || lower === "host") continue;
    result[key] = value;
  }
  if (bodyLength !== null) {
    result["content-length"] = String(bodyLength);
  }
  return result;
}

function responseHeaders(headers) {
  const result = {};
  for (const [key, value] of Object.entries(headers)) {
    if (hopByHopHeaders.has(key.toLowerCase())) continue;
    result[key] = value;
  }
  return result;
}

function targetUrl(reqUrl, upstreamBase) {
  const incoming = new URL(reqUrl, "http://proxy.local");
  let suffix;
  if (incoming.pathname === "/v1") {
    suffix = "";
  } else if (incoming.pathname.startsWith("/v1/")) {
    suffix = incoming.pathname.slice("/v1".length);
  } else {
    suffix = incoming.pathname;
  }

  const target = new URL(`${upstreamBase.replace(/\/$/, "")}${suffix}`);
  target.search = incoming.search;
  return target;
}

async function handleRequest(req, res, args) {
  if (req.url === "/__health") {
    const body = JSON.stringify({
      status: "ok",
      upstream_base: args.upstreamBase.replace(/\/$/, ""),
    });
    res.writeHead(200, {
      "content-type": "application/json",
      "content-length": Buffer.byteLength(body),
    });
    res.end(body);
    return;
  }

  let body = await readBody(req);
  const path = new URL(req.url, "http://proxy.local").pathname;
  if (req.method === "POST" && path.endsWith("/chat/completions")) {
    body = normalizePayload(body);
  }

  const target = targetUrl(req.url, args.upstreamBase);
  const options = {
    method: req.method,
    hostname: target.hostname,
    port: target.port,
    path: `${target.pathname}${target.search}`,
    headers: filteredHeaders(
      req.headers,
      req.method === "GET" || req.method === "HEAD" ? null : body.length,
    ),
    timeout: args.timeout,
  };

  const upstreamReq = http.request(options, (upstreamRes) => {
    res.writeHead(
      upstreamRes.statusCode || 502,
      responseHeaders(upstreamRes.headers),
    );
    upstreamRes.pipe(res);
  });

  upstreamReq.on("timeout", () => {
    upstreamReq.destroy(new Error("upstream request timed out"));
  });
  upstreamReq.on("error", (error) => {
    if (!res.headersSent) {
      res.writeHead(502, { "content-type": "text/plain" });
    }
    res.end(`upstream request failed: ${error.message}`);
  });

  if (req.method !== "GET" && req.method !== "HEAD") {
    upstreamReq.write(body);
  }
  upstreamReq.end();
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.selfTest) {
    selfTest();
    return;
  }

  if (!args.upstreamBase) {
    throw new Error("--upstream-base is required unless --self-test is used");
  }

  const server = http.createServer((req, res) => {
    handleRequest(req, res, args).catch((error) => {
      if (!res.headersSent) {
        res.writeHead(500, { "content-type": "text/plain" });
      }
      res.end(error.stack || error.message);
    });
  });

  server.on("error", (error) => {
    console.error(`vibe-openai-proxy failed to listen: ${error.message}`);
    process.exit(1);
  });

  server.listen(args.port, args.bind, () => {
    console.error(
      `vibe-openai-proxy listening on ${args.bind}:${args.port}, forwarding to ${args.upstreamBase}`,
    );
  });
}

main();
