import { createServer } from "node:http";
import { readFile, mkdir, writeFile, chmod } from "node:fs/promises";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DatabaseSync } from "node:sqlite";
import {
  decorateAccount,
  filesFromList,
  orgTypeFromProfile,
  planFromUsage,
  poolLabel,
  poolProblems,
  pooledWeekly,
  profileRequest,
  parseUsageBody,
  patchRoutingYaml,
  prioritiesFor,
  providerOf,
  rankForSoonestReset,
  tierFromProfile,
  tierProblem,
  usageReport,
  usageRequest,
  windowsFromCategories,
  windowsFromUsage,
} from "./lib/normalize.mjs";
import {
  summarizeCodex,
  summarizeCursorEdits,
  summarizeCursorPlan,
  summarizeOpenCode,
} from "./lib/consumption.mjs";

const API = {
  v8: {
    list: "/v8/management/credentials",
    apiCall: "/v8/management/requests/api-call",
    quotaFetch: "/v8/management/credentials/quota/fetch",
    config: "/v8/management/config.yaml",
    fields: "/v8/management/credentials/fields",
    logs: "/v8/management/logs",
  },
  v0: {
    list: "/v0/management/auth-files",
    apiCall: "/v0/management/api-call",
    quotaFetch: "",
    config: "/v0/management/config.yaml",
    fields: "/v0/management/auth-files/fields",
    logs: "/v0/management/logs",
  },
};

const root = path.dirname(fileURLToPath(import.meta.url));
const publicDir = path.join(root, "public");
const dataDir = path.join(root, "data");
const settingsPath = path.join(dataDir, "settings.json");
const port = Number(process.env.PORT || 8787);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
};

async function loadSettings() {
  try {
    const raw = await readFile(settingsPath, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed.baseUrl || !parsed.managementKey) return null;
    return {
      baseUrl: String(parsed.baseUrl).replace(/\/$/, ""),
      managementKey: String(parsed.managementKey),
      clientApiKey: parsed.clientApiKey ? String(parsed.clientApiKey) : "",
    };
  } catch {
    return null;
  }
}

async function saveSettings(settings) {
  await mkdir(dataDir, { recursive: true });
  await writeFile(settingsPath, JSON.stringify(settings, null, 2));
  await chmod(settingsPath, 0o600);
}

function send(res, status, body, type = "application/json; charset=utf-8") {
  const payload = typeof body === "string" ? body : JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": type,
    "Cache-Control": "no-store",
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const text = Buffer.concat(chunks).toString("utf8");
      if (!text) return resolve({});
      try {
        resolve(JSON.parse(text));
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

async function mgmt(settings, apiPath, { method = "GET", body, contentType } = {}) {
  const headers = { Authorization: `Bearer ${settings.managementKey}` };
  let payload;
  if (body != null) {
    if (contentType === "application/yaml") {
      headers["Content-Type"] = "application/yaml";
      payload = body;
    } else {
      headers["Content-Type"] = "application/json";
      payload = JSON.stringify(body);
    }
  }
  const response = await fetch(`${settings.baseUrl}${apiPath}`, {
    method,
    headers,
    body: payload,
    signal: AbortSignal.timeout(12000),
  });
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = null;
  }
  if (!response.ok) {
    const message = json?.message || json?.error || text.slice(0, 280) || response.statusText;
    const error = new Error(message);
    error.status = response.status;
    throw error;
  }
  return { text, json };
}

async function mgmtFirst(settings, paths, options) {
  let lastError = null;
  for (const apiPath of paths.filter(Boolean)) {
    try {
      return await mgmt(settings, apiPath, options);
    } catch (error) {
      lastError = error;
      if (error.status !== 404 && error.status !== 405) throw error;
    }
  }
  if (lastError) throw lastError;
  throw new Error("No management path configured");
}

async function detectApi(settings) {
  try {
    const listed = await mgmt(settings, API.v8.list);
    return { version: "v8", paths: API.v8, listed };
  } catch (error) {
    if (error.status !== 404 && error.status !== 405) throw error;
  }
  const listed = await mgmt(settings, API.v0.list);
  return { version: "v0", paths: API.v0, listed };
}

function reportFromBody(provider, body) {
  const report = usageReport(provider, body);
  const windows = report.categories.length
    ? windowsFromCategories(report.categories)
    : windowsFromUsage(provider, body);
  return { windows, categories: report.categories, extraUsage: report.extra, quotaError: "", plan: planFromUsage(provider, body) };
}

async function windowsFor(settings, paths, file) {
  const provider = providerOf(file);
  const authIndex = file.auth_index || file.authIndex;
  const empty = { windows: [], categories: [], extraUsage: null, quotaError: "" };
  if (!authIndex || file.disabled) return empty;

  if (paths.quotaFetch) {
    try {
      const fetched = await mgmt(settings, paths.quotaFetch, {
        method: "POST",
        body: { auth_index: authIndex, provider },
      });
      const body = fetched.json?.body ? parseUsageBody(fetched.json.body) : fetched.json;
      const report = reportFromBody(provider, body);
      if (report.windows.length || report.categories.length) return report;
    } catch (error) {
      if (error.status !== 404 && error.status !== 405 && error.status !== 501) {
        return { ...empty, quotaError: error.message };
      }
    }
  }

  const request = usageRequest(provider);
  if (!request) return empty;
  try {
    const called = await mgmt(settings, paths.apiCall, {
      method: "POST",
      body: { auth_index: authIndex, ...request },
    });
    const upstream = called.json || {};
    if (upstream.status_code && upstream.status_code >= 400) {
      return { ...empty, quotaError: `usage endpoint returned ${upstream.status_code}` };
    }
    return reportFromBody(provider, parseUsageBody(upstream.body));
  } catch (error) {
    return { ...empty, quotaError: error.message };
  }
}

async function tierFor(settings, paths, file) {
  const request = profileRequest(providerOf(file));
  const authIndex = file.auth_index || file.authIndex;
  if (!request || !authIndex || file.disabled) return { tier: "", orgType: "", error: "" };
  try {
    const called = await mgmt(settings, paths.apiCall, {
      method: "POST",
      body: { auth_index: authIndex, ...request },
    });
    const upstream = called.json || {};
    if (upstream.status_code && upstream.status_code >= 400) {
      return { tier: "", orgType: "", error: `profile call returned ${upstream.status_code}` };
    }
    const profile = parseUsageBody(upstream.body);
    const tier = tierFromProfile(profile);
    return { tier, orgType: orgTypeFromProfile(profile), error: tierProblem(tier) };
  } catch (error) {
    return { tier: "", orgType: "", error: `profile call failed (${error.message})` };
  }
}

async function localAccountMeta(file) {
  const filePath = String(file?.path || "");
  const authDir = path.join(os.homedir(), ".cli-proxy-api") + path.sep;
  if (!filePath.startsWith(authDir)) return {};
  try {
    const parsed = JSON.parse(await readFile(filePath, "utf8"));
    return {
      organization: typeof parsed.organization_name === "string" ? parsed.organization_name : "",
      plan: typeof parsed.subscription_type === "string" ? parsed.subscription_type : "",
      apiKey: Boolean(parsed.api_key),
    };
  } catch {
    return {};
  }
}

async function codexLoginType() {
  try {
    const auth = JSON.parse(await readFile(path.join(os.homedir(), ".codex/auth.json"), "utf8"));
    if (auth.auth_mode === "apikey") return "API key";
    if (auth.auth_mode === "chatgpt") return "ChatGPT login";
    return auth.auth_mode ? String(auth.auth_mode) : "";
  } catch {
    return "";
  }
}

async function loadBoard(settings) {
  const api = await detectApi(settings);
  const files = filesFromList(api.listed.json);
  const accounts = [];
  for (const file of files) {
    const usage = await windowsFor(settings, api.paths, file);
    const meta = await localAccountMeta(file);
    const profile = await tierFor(settings, api.paths, file);
    const account = decorateAccount(file, usage.windows, {
      ...meta,
      plan: meta.plan || usage.plan,
      tier: profile.tier,
      orgType: profile.orgType,
      tierError: profile.error,
      categories: usage.categories,
      extraUsage: usage.extraUsage,
    });
    account.quotaError = usage.quotaError;
    accounts.push(account);
  }
  return { source: "live", api: api.version, accounts };
}

async function listAccounts(settings) {
  const api = await detectApi(settings);
  return {
    api: api.version,
    accounts: filesFromList(api.listed.json).map((file) => decorateAccount(file, [])),
  };
}

function publicSettings(settings) {
  if (!settings) return { connected: false };
  return {
    connected: true,
    baseUrl: settings.baseUrl,
    clientApiKeySet: Boolean(settings.clientApiKey),
  };
}

async function applyRouting(settings, mode, websockets) {
  const strategy = mode === "even" ? "round-robin" : "fill-first";
  const api = await detectApi(settings);
  if (mode !== "sockets") {
    const current = await mgmtFirst(settings, [api.paths.config, API.v0.config]);
    const patched = patchRoutingYaml(current.text, {
      strategy,
      sessionAffinity: true,
    });
    if (!patched.ok) {
      const error = new Error(
        "The routing block is inline YAML. Edit config.yaml by hand and set strategy plus session-affinity.",
      );
      error.status = 422;
      throw error;
    }
    await mgmtFirst(settings, [api.paths.config, API.v0.config], {
      method: "PUT",
      body: patched.yaml,
      contentType: "application/yaml",
    });
  }

  const board = mode === "sockets" ? await listAccounts(settings) : await loadBoard(settings);
  const haveResets = board.accounts.some((account) => account.weeklyResetMs != null);
  const priorities = mode === "soonest" && haveResets ? prioritiesFor(board.accounts) : [];
  const priorityResults = [];
  for (const item of priorities) {
    try {
      await mgmtFirst(settings, [api.paths.fields, API.v0.fields], {
        method: "PATCH",
        body: { name: item.name, priority: item.priority },
      });
      priorityResults.push({ name: item.name, priority: item.priority, ok: true });
    } catch (error) {
      priorityResults.push({ name: item.name, priority: item.priority, ok: false, error: error.message });
    }
  }

  const socketResults = [];
  if (websockets != null) {
    for (const account of board.accounts.filter((item) => item.provider === "codex")) {
      try {
        await mgmtFirst(settings, [api.paths.fields, API.v0.fields], {
          method: "PATCH",
          body: { name: account.name, websockets: Boolean(websockets) },
        });
        socketResults.push({ name: account.name, ok: true });
      } catch (error) {
        socketResults.push({ name: account.name, ok: false, error: error.message });
      }
    }
  }

  return {
    strategy: mode === "sockets" ? null : strategy,
    sessionAffinity: mode !== "sockets",
    priorities: priorityResults,
    websockets: socketResults,
    warning: mode === "soonest" && !haveResets
      ? "Routing is fill-first, but quota windows were not readable, so account priority was left as it was."
      : "",
  };
}

async function handleApi(req, res, url) {
  if (req.method === "GET" && url.pathname === "/api/status") {
    return send(res, 200, publicSettings(await loadSettings()));
  }

  if (req.method === "POST" && url.pathname === "/api/settings") {
    const body = await readBody(req);
    const baseUrl = String(body.baseUrl || "").trim().replace(/\/$/, "");
    const managementKey = String(body.managementKey || "");
    if (!/^https?:\/\//.test(baseUrl) || !managementKey) {
      return send(res, 400, { error: "Need an http(s) proxy URL and a management key." });
    }
    const settings = {
      baseUrl,
      managementKey,
      clientApiKey: String(body.clientApiKey || ""),
    };
    await detectApi(settings);
    await saveSettings(settings);
    return send(res, 200, publicSettings(settings));
  }

  if (req.method === "DELETE" && url.pathname === "/api/settings") {
    await saveSettings({ baseUrl: "", managementKey: "", clientApiKey: "" }).catch(() => {});
    if (existsSync(settingsPath)) {
      await writeFile(settingsPath, "{}\n");
      await chmod(settingsPath, 0o600);
    }
    return send(res, 200, { connected: false });
  }

  if (req.method === "GET" && url.pathname === "/api/board") {
    const settings = await loadSettings();
    if (!settings?.managementKey) {
      return send(res, 200, { source: "demo", accounts: [] });
    }
    try {
      const board = await loadBoard(settings);
      const groups = groupBoard(board.accounts);
      return send(res, 200, { ...board, groups, preferred: prioritiesFor(board.accounts)[0] || null });
    } catch (error) {
      return send(res, error.status || 502, { error: error.message });
    }
  }

  if (req.method === "POST" && url.pathname === "/api/routing") {
    const settings = await loadSettings();
    if (!settings?.managementKey) {
      return send(res, 409, { error: "Connect the proxy first." });
    }
    const body = await readBody(req);
    const mode = body.mode === "even" || body.mode === "sockets" ? body.mode : "soonest";
    try {
      const result = await applyRouting(settings, mode, body.websockets);
      return send(res, 200, result);
    } catch (error) {
      return send(res, error.status || 502, { error: error.message });
    }
  }

  if (req.method === "GET" && url.pathname === "/api/consumption") {
    try {
      return send(res, 200, await collectConsumption());
    } catch (error) {
      return send(res, 500, { error: error.message || "Could not read local usage" });
    }
  }

  if (req.method === "GET" && url.pathname === "/api/logs") {
    const settings = await loadSettings();
    if (!settings?.managementKey) return send(res, 200, { lines: [] });
    try {
      const after = url.searchParams.get("after") || "";
      const query = after ? `?after=${encodeURIComponent(after)}` : "";
      const api = await detectApi(settings);
      const logs = await mgmtFirst(settings, [`${api.paths.logs}${query}`, `${API.v0.logs}${query}`]);
      return send(res, 200, logs.json || { lines: [] });
    } catch (error) {
      return send(res, error.status || 502, { error: error.message });
    }
  }

  return send(res, 404, { error: "not found" });
}

function readRows(dbPath, sql) {
  if (!existsSync(dbPath)) return [];
  const db = new DatabaseSync(dbPath, { readOnly: true });
  try {
    return db.prepare(sql).all();
  } finally {
    db.close();
  }
}

function tryRows(dbPath, sql) {
  try {
    return { rows: readRows(dbPath, sql), error: "" };
  } catch (error) {
    return { rows: [], error: error.message || "Could not read the local database" };
  }
}

function cellText(value) {
  if (typeof value === "string") return value;
  if (value == null) return "";
  return Buffer.from(value).toString("utf8");
}

async function cursorPlan() {
  const dbPath = path.join(os.homedir(), ".config/Cursor/User/globalStorage/state.vscdb");
  const rows = existsSync(dbPath)
    ? readRows(dbPath, "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken'")
    : [];
  const token = cellText(rows[0]?.value).trim();
  if (!token) return { plan: null, error: "No Cursor login on this machine." };
  const response = await fetch("https://api2.cursor.sh/auth/usage-summary", {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) return { plan: null, error: `Cursor usage returned ${response.status}` };
  return { plan: summarizeCursorPlan(await response.json()), error: "" };
}

async function collectConsumption() {
  const home = os.homedir();
  const opencodeRead = tryRows(
    path.join(home, ".local/share/opencode/opencode.db"),
    `SELECT model,
            COUNT(*) AS sessions,
            COALESCE(SUM(tokens_input), 0) AS input,
            COALESCE(SUM(tokens_output), 0) AS output,
            COALESCE(SUM(tokens_reasoning), 0) AS reasoning,
            COALESCE(SUM(tokens_cache_read), 0) AS cacheRead,
            COALESCE(SUM(cost), 0) AS cost
     FROM session_v2
     GROUP BY model`,
  );
  const { opencode, bedrock } = summarizeOpenCode(opencodeRead.rows);
  const codexRead = tryRows(
    path.join(home, ".codex/state_5.sqlite"),
    `SELECT model,
            model_provider AS provider,
            COUNT(*) AS sessions,
            COALESCE(SUM(tokens_used), 0) AS tokens
     FROM threads
     GROUP BY model, model_provider`,
  );
  const codex = summarizeCodex(codexRead.rows);
  const codexType = await codexLoginType();
  const editRead = tryRows(
    path.join(home, ".cursor/ai-tracking/ai-code-tracking.db"),
    "SELECT model, COUNT(*) AS edits FROM ai_code_hashes GROUP BY model",
  );
  const edits = summarizeCursorEdits(editRead.rows);
  let cursor = { plan: null, error: "" };
  try {
    cursor = await cursorPlan();
  } catch (error) {
    cursor = { plan: null, error: error.message || "Cursor usage could not be read" };
  }
  return {
    groups: [
      {
        id: "codex",
        title: "Codex",
        source: "Local Codex threads",
        accountType: codexType,
        note: codexRead.error || (codexType === "API key"
          ? "Token totals stored on Codex threads. This login is an API key, so there is no 5-hour or weekly subscription window to read."
          : "Token totals stored on Codex threads."),
        rows: codex,
      },
      {
        id: "opencode",
        title: "OpenCode",
        accountType: opencode.length ? `providers: ${[...new Set(opencode.map((row) => row.detail))].join(", ")}` : "",
        source: "OpenCode session history",
        note: opencodeRead.error || "Input, output, and cache-read tokens OpenCode recorded on finished sessions.",
        rows: opencode,
      },
      {
        id: "bedrock",
        title: "Bedrock",
        accountType: bedrock.length ? "AWS pay per use" : "",
        source: "OpenCode sessions on amazon-bedrock",
        note: bedrock.some((row) => row.input + row.output > 0)
          ? "Tokens OpenCode recorded for Amazon Bedrock models."
          : "OpenCode started Bedrock sessions, but those requests stored no tokens. Bedrock rejected them before a completion was counted.",
        rows: bedrock,
      },
      {
        id: "cursor",
        title: "Cursor",
        accountType: cursor.plan?.membership ? cursor.plan.membership.charAt(0).toUpperCase() + cursor.plan.membership.slice(1) : "",
        source: "Cursor account, this billing cycle",
        note: cursor.error || "Included allowance is the purchased monthly amount. Auto and API percents are Cursor's own meters. Editor edits are local code-tracking events, not tokens.",
        plan: cursor.plan,
        edits,
      },
    ],
  };
}

function groupBoard(accounts) {
  const groups = new Map();
  for (const account of accounts) {
    if (!groups.has(account.provider)) groups.set(account.provider, []);
    groups.get(account.provider).push(account);
  }
  return [...groups.entries()].map(([provider, items]) => ({
    provider,
    pooledWeekly: pooledWeekly(items),
    poolLabel: poolLabel(items),
    problems: poolProblems(items),
    accounts: rankForSoonestReset(items),
  }));
}

async function handleStatic(req, res, url) {
  const requested = url.pathname === "/" ? "/index.html" : url.pathname;
  const filePath = path.normalize(path.join(publicDir, requested));
  if (!filePath.startsWith(publicDir)) return send(res, 403, { error: "forbidden" });
  try {
    const data = await readFile(filePath);
    const ext = path.extname(filePath);
    res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
    res.end(data);
  } catch {
    send(res, 404, "Not found", "text/plain; charset=utf-8");
  }
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://127.0.0.1:${port}`);
  try {
    if (url.pathname.startsWith("/api/")) await handleApi(req, res, url);
    else await handleStatic(req, res, url);
  } catch (error) {
    send(res, 500, { error: error.message || "server error" });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`cliproxy console  http://127.0.0.1:${port}`);
});
