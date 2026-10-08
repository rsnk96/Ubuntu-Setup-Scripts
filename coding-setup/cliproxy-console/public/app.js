const main = document.querySelector("#main");
const navButtons = [...document.querySelectorAll(".nav-btn")];

const pages = ["quota", "routing", "clients", "logs", "proxy"];
const requested = new URLSearchParams(location.search).get("page");
const state = {
  page: pages.includes(requested) ? requested : "quota",
  filter: "all",
  status: { connected: false },
  board: null,
  consumption: null,
  error: "",
  routingNote: "",
  logs: "",
  busy: false,
  clientKey: localStorage.getItem("cliproxy-console-client-key") || "",
};

navButtons.forEach((button) => {
  button.addEventListener("click", () => {
    state.page = button.dataset.page;
    render();
    if (state.page === "logs") loadLogs();
    if (state.page === "quota") loadBoard();
  });
});

function hoursFromNow(hours) {
  return new Date(Date.now() + hours * 3600000).toISOString();
}

function sampleBoard() {
  const accounts = [
    account("claude", "claude-a•••@example.com.json", "Max", 68, 24, 100, 5, 20, 72),
    account("claude", "claude-a•••@example.com.json", "Max", 100, 96, 100, 5, 100, 96),
    account("claude", "claude-a•••@example.com.json", "Max", 100, 120, 100, 5, 100, 120),
    account("claude", "claude-a•••@example.com.json", "Max", 81, 28, 99, 4, 70, 48),
    account("codex", "codex-a•••@example.com.json", "Plus", 17, 80, 100, 3, null, null),
  ];
  return { source: "demo", accounts, groups: group(accounts) };
}

function account(provider, name, plan, weekly, weeklyHours, five, fiveHours, extra, extraHours) {
  const windows = [
    { slot: "weekly", label: "Current week (all models)", remaining: weekly, resetsAt: hoursFromNow(weeklyHours) },
    { slot: "fiveHour", label: "Current session", remaining: five, resetsAt: hoursFromNow(fiveHours) },
  ];
  const categories = [
    meter("Current session", "session", "fiveHour", 100 - five, five, hoursFromNow(fiveHours), true),
    meter("Current week (all models)", "weekly", "weekly", 100 - weekly, weekly, hoursFromNow(weeklyHours), true),
  ];
  if (extra != null) {
    windows.push({
      slot: "extra",
      label: "Current week (Opus only)",
      remaining: extra,
      resetsAt: hoursFromNow(extraHours),
    });
    categories.push(meter("Current week (Opus only)", "weekly", "extra", 100 - extra, extra, hoursFromNow(extraHours), true));
  }
  return {
    name,
    displayName: name,
    email: name,
    organization: "",
    provider,
    plan,
    accountType: provider === "claude" ? "Max 5x" : plan,
    capacity: provider === "claude" ? 5 : null,
    tierLabel: provider === "claude" ? "Max 5x" : "",
    status: "ready",
    disabled: false,
    cooldownCount: 0,
    exhausted: weekly === 0 || five === 0,
    weeklyResetMs: Date.parse(windows[0].resetsAt),
    windows,
    categories,
    extraUsage: { enabled: false, reason: "out_of_credits", spendLimitReached: false, utilization: null },
    quotaError: "",
  };
}

function meter(title, group, slot, used, remaining, resetsAt, active) {
  return { title, group, slot, used, remaining, resetsAt, active, severity: "normal" };
}

function pooledWeekly(items) {
  const weekly = (item) => item.windows.find((w) => w.slot === "weekly").remaining;
  if (items.some((item) => !item.capacity)) return null;
  const total = items.reduce((sum, item) => sum + item.capacity, 0);
  return Math.round(items.reduce((sum, item) => sum + item.capacity * weekly(item), 0) / total);
}

function poolLabel(items) {
  const counts = new Map();
  for (const item of items) counts.set(item.tierLabel, (counts.get(item.tierLabel) || 0) + 1);
  return [...counts.entries()].map(([label, count]) => `${count} × ${label}`).join(" + ");
}

function group(accounts) {
  const map = new Map();
  for (const item of accounts) {
    if (!map.has(item.provider)) map.set(item.provider, []);
    map.get(item.provider).push(item);
  }
  return [...map.entries()].map(([provider, items]) => ({
    provider,
    pooledWeekly: pooledWeekly(items),
    poolLabel: poolLabel(items),
    problems: [],
    accounts: items,
  }));
}

function formatReset(iso) {
  if (!iso) return "reset time unknown";
  const ms = Date.parse(iso) - Date.now();
  if (!Number.isFinite(ms)) return "reset time unknown";
  if (ms <= 0) return "reset due";
  const minutes = Math.round(ms / 60000);
  if (minutes < 90) return `in ${minutes} min`;
  const hours = Math.round(ms / 3600000);
  if (hours < 20) return `in ${hours} hour${hours === 1 ? "" : "s"}`;
  const days = Math.round(ms / 86400000);
  return `in ${days} day${days === 1 ? "" : "s"}`;
}

function tone(remaining) {
  if (remaining == null) return "";
  if (remaining < 20) return "low";
  if (remaining < 100) return "mid";
  return "";
}

function preferredName(board) {
  const open = (board?.accounts || []).filter((item) => !item.exhausted && item.weeklyResetMs);
  open.sort((a, b) => a.weeklyResetMs - b.weeklyResetMs);
  return open[0]?.name || "";
}

async function loadStatus() {
  const response = await fetch("/api/status");
  state.status = await response.json();
}

async function loadBoard() {
  state.busy = true;
  render();
  try {
    const [response, usageResponse] = await Promise.all([
      fetch("/api/board"),
      fetch("/api/consumption"),
    ]);
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || "Could not read the proxy");
    state.board = body.source === "live" ? body : sampleBoard();
    state.consumption = usageResponse.ok ? await usageResponse.json() : null;
    state.error = "";
  } catch (error) {
    state.error = error.message;
    state.board = sampleBoard();
  } finally {
    state.busy = false;
    render();
  }
}

async function loadLogs() {
  const response = await fetch("/api/logs");
  const body = await response.json();
  state.logs = body.error
    ? body.error
    : (body.lines || []).join("\n") || "No log lines yet. Connect the proxy, then come back.";
  if (state.page === "logs") render();
}

function proxyBase() {
  return state.status.baseUrl || "http://127.0.0.1:8317";
}

function render() {
  navButtons.forEach((button) => {
    button.classList.toggle("active", button.dataset.page === state.page);
  });
  const pages = { quota: renderQuota, routing: renderRouting, clients: renderClients, logs: renderLogs, proxy: renderProxy };
  main.innerHTML = pages[state.page]();
  bind();
}

function renderQuota() {
  const board = state.board || sampleBoard();
  const providers = ["all", ...new Set([
    ...board.accounts.map((item) => item.provider),
    ...(state.consumption?.groups || []).map((item) => item.id),
  ])];
  const next = preferredName(board);
  const groups = (board.groups || group(board.accounts)).filter(
    (item) => state.filter === "all" || item.provider === state.filter,
  );
  const banner = board.source === "demo"
    ? `<div class="banner">Sample board. Connect CLIProxy on the Proxy page to replace it with your own accounts.</div>`
    : "";
  const apiProblems = (board.groups || []).flatMap((item) => item.problems || []);
  const error = [
    state.error,
    apiProblems.length ? `Quota data is incomplete. The provider API may have changed: ${apiProblems.join("; ")}` : "",
  ].filter(Boolean).map((text) => `<div class="banner bad">${escapeHtml(text)}</div>`).join("");
  return `
    <h1>Quota</h1>
    <p class="lede">Each account shows the same buckets as <code>/usage</code>: the current session, the week across all models, and any model week Claude reports. A thread stays put until its account is actually out of quota.</p>
    ${banner}${error}
    <div class="row toolbar">
      <div class="chips">
        ${providers.map((provider) => `<button class="chip ${state.filter === provider ? "active" : ""}" data-filter="${escapeAttr(provider)}">${provider}</button>`).join("")}
      </div>
      <button class="btn" id="refresh" ${state.busy ? "disabled" : ""}>${state.busy ? "Reading…" : "Refresh"}</button>
    </div>
    <section class="cards">
      ${groups.slice(0, 4).map(summaryCard).join("")}
    </section>
    ${groups.map((item) => renderGroup(item, next)).join("")}
    ${renderConsumption()}
    <section class="panel">
      <h2>What the rows mean</h2>
      <div class="legend">
        <div><strong>Current session</strong> The 5-hour burst cap. This is the first meter <code>/usage</code> prints.</div>
        <div><strong>Current week (all models)</strong> The shared 7-day pool. When it ends, what is left is gone.</div>
        <div><strong>Current week (Fable, Sonnet, Opus)</strong> A model-only slice, shown only when Claude sends one. A slice that is not counting yet is dimmed. It does not choose the account.</div>
        <div><strong>Extra usage</strong> The credit balance <code>/usage</code> shows after the plan windows. Off means the plan limits are the only cap.</div>
        <div><strong>Quota failover</strong> A thread keeps its account, including the prompt cache, until that account returns a quota error. The proxy then retries that request on the other account and the thread stays on the new one. If both are out, the thread stops.</div>
        <div><strong>Resets first</strong> The bright row is the open account whose weekly window ends soonest. Round-robin still spreads brand-new threads. Fill-first, on the Routing page, spends this row first.</div>
      </div>
    </section>
  `;
}

function renderConsumption() {
  const groups = (state.consumption?.groups || []).filter(
    (item) => state.filter === "all" || item.id === state.filter,
  );
  if (!groups.length) return "";
  return `
    <h2 class="group-title">Other clients</h2>
    ${groups.map(renderConsumptionGroup).join("")}
  `;
}

function renderConsumptionGroup(group) {
  const rows = group.id === "cursor" ? renderCursor(group) : (group.rows || []).map(renderSpendRow).join("");
  return `
    <h2 class="group-title">${escapeHtml(group.title)}${group.accountType ? ` <span class="plan">${escapeHtml(group.accountType)}</span>` : ""}</h2>
    <p class="source-note">${escapeHtml(group.note || "")}</p>
    ${rows || `<p class="source-note">Nothing recorded.</p>`}
  `;
}

function renderSpendRow(row) {
  const bits = [];
  if (row.tokens != null) bits.push(["Tokens recorded", formatCount(row.tokens)]);
  if (row.input != null) bits.push(["Input", formatCount(row.input)]);
  if (row.output != null) bits.push(["Output", formatCount(row.output)]);
  if (row.cacheRead) bits.push(["Cache read", formatCount(row.cacheRead)]);
  if (row.reasoning) bits.push(["Reasoning", formatCount(row.reasoning)]);
  if (row.cost) bits.push(["Cost recorded", `$${Number(row.cost).toFixed(2)}`]);
  if (row.edits != null) bits.push(["Editor edits", formatCount(row.edits)]);
  const meters = bits.map(([label, value]) => `<div class="window"><div class="wh"><span>${escapeHtml(label)}</span><b>${escapeHtml(value)}</b></div></div>`).join("");
  const detail = [
    row.sessions != null ? `${row.sessions} session${row.sessions === 1 ? "" : "s"}` : "",
    row.detail && row.detail !== row.label ? row.detail : "",
  ].filter(Boolean).join(" · ");
  return `
    <article class="account">
      <div>
        <div class="file">${escapeHtml(row.label)}</div>
        ${detail ? `<div class="plan">${escapeHtml(detail)}</div>` : ""}
      </div>
      <div class="windows">${meters}</div>
    </article>
  `;
}

function renderCursor(group) {
  const plan = group.plan;
  const edits = (group.edits || []).map(renderSpendRow).join("");
  if (!plan) return edits;
  const included = plan.includedLimitCents
    ? Math.round((plan.includedUsedCents / plan.includedLimitCents) * 100)
    : null;
  const cycle = [formatDay(plan.cycleStart), formatDay(plan.cycleEnd)].filter(Boolean).join(" – ");
  const meters = [
    meterLine("Included allowance", included, `${formatDollars(plan.includedUsedCents)} of ${formatDollars(plan.includedLimitCents)}`),
    meterLine("Auto models", plan.autoPercent, `${Math.round(plan.autoPercent)}% used`),
    meterLine("API models", plan.apiPercent, `${Math.round(plan.apiPercent)}% used`),
  ].join("");
  const bonus = plan.bonusCents
    ? `<div class="usage-foot"><span>Bonus usage</span><b>${escapeHtml(formatDollars(plan.bonusCents))}</b></div>`
    : "";
  return `
    <article class="account">
      <div>
        <div class="file">${escapeHtml(plan.membership)}</div>
        <div class="plan">${escapeHtml(cycle)}</div>
        <div class="meta"><span class="pill">${plan.onDemandEnabled ? "on-demand on" : "on-demand off"}</span></div>
      </div>
      <div class="windows">${meters}${bonus}</div>
    </article>
    ${edits}
  `;
}

function meterLine(title, percent, caption) {
  const width = percent == null ? 0 : Math.max(0, Math.min(100, percent));
  return `<div class="window"><div class="wh"><span>${escapeHtml(title)}</span><b>${escapeHtml(caption)}</b></div><div class="bar"><i class="${tone(100 - width)}" style="width:${width}%"></i></div></div>`;
}

function formatCount(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "—";
  const abs = Math.abs(n);
  if (abs >= 1_000_000_000) return `${trimCount(n / 1_000_000_000)}B`;
  if (abs >= 1_000_000) return `${trimCount(n / 1_000_000)}M`;
  if (abs >= 10_000) return `${trimCount(n / 1_000)}K`;
  return String(Math.round(n));
}

function trimCount(n) {
  const text = n.toFixed(1);
  return text.endsWith(".0") ? text.slice(0, -2) : text;
}

function formatDollars(cents) {
  const n = Number(cents);
  if (!Number.isFinite(n)) return "—";
  return `$${(n / 100).toFixed(2)}`;
}

function formatDay(iso) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function summaryCard(group) {
  if (group.problems?.length) {
    return `<article class="card bad"><div class="k">${escapeHtml(group.provider)}</div><div class="n">Unavailable</div><div class="sub">${group.problems.map(escapeHtml).join("<br>")}</div></article>`;
  }
  const left = group.pooledWeekly;
  const used = left == null ? null : 100 - left;
  const shown = used == null ? "—" : `${used}%`;
  const sub = used == null ? `no pooled 7-day view for ${escapeHtml(group.provider)}` : `pooled 7-day used · ${escapeHtml(group.poolLabel)}`;
  return `<article class="card"><div class="k">${escapeHtml(group.provider)}</div><div class="n">${shown}</div><div class="bar"><i class="${tone(left)}" style="width:${used ?? 0}%"></i></div><div class="sub">${sub}</div></article>`;
}

function renderGroup(group, next) {
  return `
    <h2 class="group-title">${escapeHtml(group.provider)}</h2>
    ${group.accounts.map((account) => renderAccount(account, account.name === next)).join("")}
  `;
}

function renderAccount(account, isNext) {
  const categories = account.categories?.length
    ? account.categories
    : (account.windows || []).map((window) => ({
      title: window.label,
      used: window.remaining == null ? null : Math.max(0, 100 - window.remaining),
      remaining: window.remaining,
      resetsAt: window.resetsAt,
      active: window.slot !== "extra",
      severity: "normal",
    }));
  const meters = categories.map(renderMeter).join("");
  const extra = extraLine(account.extraUsage);
  return `
    <article class="account ${isNext ? "next" : ""}">
      <div>
        <div class="file">${escapeHtml(account.displayName || account.name)}</div>
        ${account.organization ? `<div class="plan">${escapeHtml(account.organization)}</div>` : ""}
        <div class="meta">
          ${account.accountType || account.plan ? `<span class="plan">${escapeHtml(account.accountType || account.plan)}</span>` : ""}
          <span class="pill">${escapeHtml(account.status || "ready")}</span>
          ${account.cooldownCount ? `<span class="pill next">cooling down</span>` : ""}
          ${isNext ? `<span class="pill next">resets first</span>` : ""}
        </div>
        ${account.quotaError ? `<div class="err">${escapeHtml(account.quotaError)}</div>` : ""}
      </div>
      <div class="windows">${meters}${extra}</div>
    </article>
  `;
}

function renderMeter(category) {
  const quiet = category.slot === "extra" && category.active === false;
  const used = category.used == null ? "—" : `${category.used}% used`;
  const left = category.remaining == null ? "" : `${category.remaining}% left`;
  const reset = category.resetsAt
    ? formatReset(category.resetsAt)
    : category.used
      ? "reset time unknown"
      : "not started";
  const when = quiet
    ? "not counting yet"
    : [
      left,
      reset,
      category.severity && category.severity !== "normal" ? category.severity : "",
    ].filter(Boolean).join(" · ");
  return `<div class="window ${quiet ? "dim" : ""}"><div class="wh"><span>${escapeHtml(category.title)}</span><b>${escapeHtml(used)}</b></div><div class="bar ${quiet ? "dim" : ""}"><i class="${tone(category.remaining)}" style="width:${category.used ?? 0}%"></i></div><div class="when">${escapeHtml(when)}</div></div>`;
}

function extraLine(extra) {
  if (!extra) return "";
  let state = "not reported";
  if (extra.enabled) {
    state = extra.utilization == null ? "on" : `on · ${extra.utilization}% used`;
  } else if (extra.spendLimitReached) {
    state = "spend limit reached";
  } else if (extra.reason === "out_of_credits") {
    state = "off · no credits loaded";
  } else if (extra.reason) {
    state = `off · ${extra.reason.replaceAll("_", " ")}`;
  } else {
    state = "off";
  }
  return `<div class="usage-foot"><span>Extra usage</span><b>${escapeHtml(state)}</b></div>`;
}

function renderRouting() {
  return `
    <h1>Routing</h1>
    <p class="lede">Round-robin spreads new sessions across accounts. Fill-first spends the account whose weekly window ends soonest. Either way, a thread stays on its account until that account hits quota, then the same request is retried on the other one.</p>
    ${state.routingNote ? `<div class="banner">${escapeHtml(state.routingNote)}</div>` : ""}
    <section class="panel">
      <h2>Where a new session goes</h2>
      <div class="choice">
        <button class="btn primary" id="soonest" ${state.busy ? "disabled" : ""}>Prefer soonest weekly reset</button>
        <button class="btn" id="even" ${state.busy ? "disabled" : ""}>Spread evenly</button>
      </div>
      <p class="help">Soonest-reset writes <code>routing.strategy: fill-first</code>, turns session affinity on, and sets a higher priority on the account that resets first. Spreading evenly switches the strategy back to round-robin and leaves affinity on. Affinity holds a thread to one account. A quota error makes that account unavailable, the proxy retries the request on another account (up to three extra rounds), and the thread then stays on the account it moved to.</p>
    </section>
    <section class="panel">
      <h2>Codex websocket</h2>
      <p class="help">Codex subscriptions do not use the websocket transport unless the credential asks for it. Turning it on shortens the round trip. This only patches Codex auth files.</p>
      <div class="choice">
        <button class="btn" id="ws-on" ${state.busy ? "disabled" : ""}>Enable websocket</button>
        <button class="btn" id="ws-off" ${state.busy ? "disabled" : ""}>Leave HTTP</button>
      </div>
    </section>
  `;
}

function renderClients() {
  const base = proxyBase();
  const key = state.clientKey || "YOUR_PROXY_API_KEY";
  return `
    <h1>Clients</h1>
    <p class="lede">All three use the client key in <code>access.api-keys</code>. That is not the management key, and it is not a Claude OAuth token.</p>
    <section class="panel">
      <label for="client-key">Proxy API key used in the snippets</label>
      <input id="client-key" type="password" value="${escapeAttr(state.clientKey)}" placeholder="paste the api-keys value" autocomplete="off" />
    </section>
    <section class="panel">
      <h2>Claude Code</h2>
      <p class="help">In <code>~/.claude/settings.json</code>. The base URL has no <code>/v1</code>; Claude Code adds <code>/v1/messages</code> itself. Sign each subscription in with <code>cli-proxy-api --claude-login</code>, once per account.</p>
      <pre class="snippet">${escapeHtml(`{
  "env": {
    "ANTHROPIC_BASE_URL": "${base}",
    "ANTHROPIC_AUTH_TOKEN": "${key}",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1"
  }
}`)}</pre>
    </section>
    <section class="panel">
      <h2>OpenCode</h2>
      <p class="help">In <code>~/.config/opencode/opencode.json</code>. OpenCode's Anthropic provider appends <code>/messages</code>, so its base URL includes <code>/v1</code>. The OpenAI provider uses the same <code>/v1</code> prefix.</p>
      <pre class="snippet">${escapeHtml(opencodeSnippet(base, key))}</pre>
    </section>
    <section class="panel">
      <h2>Cursor Agent</h2>
      <p class="help">Cursor has no Anthropic base-URL override, so Claude models in Cursor stay on Anthropic's own host. The path that does work is Settings, Models, API Keys, Override OpenAI Base URL. While that override is on, OpenAI-family requests go to the proxy. Turn it off when you want Cursor's own subscription models. Add a custom model whose id is one returned by <code>GET /v1/models</code>.</p>
      <pre class="snippet">${escapeHtml(`Override OpenAI Base URL: ${base}/v1
OpenAI API Key:             ${key}`)}</pre>
    </section>
  `;
}

function opencodeSnippet(base, key) {
  return JSON.stringify({
    $schema: "https://opencode.ai/config.json",
    provider: {
      anthropic: {
        options: { baseURL: `${base}/v1`, apiKey: key },
      },
      openai: {
        options: { baseURL: `${base}/v1`, apiKey: key },
      },
    },
  }, null, 2);
}

function renderLogs() {
  return `
    <h1>Logs</h1>
    <p class="lede">Recent lines from the proxy management log.</p>
    <div class="row"><button class="btn" id="reload-logs">Reload</button></div>
    <div class="logbox">${escapeHtml(state.logs || "Loading…")}</div>
  `;
}

function renderProxy() {
  const connected = state.status.connected
    ? `Connected to ${state.status.baseUrl}`
    : "Not connected. The quota page is showing the sample board.";
  return `
    <h1>Proxy</h1>
    <p class="lede">${escapeHtml(connected)}</p>
    <section class="panel">
      <h2>CLIProxy management API</h2>
      <p class="help">CLIProxyAPI v8 listens on port 8317. The management key is <code>management.secret-key</code> in <code>config.yaml</code>. Run <code>cli-proxy-api --claude-login</code> once for each Claude subscription. This page stores that key in <code>data/settings.json</code> and does not print it back. It talks to <code>/v8/management</code> and falls back to <code>/v0/management</code> if v8 is not there.</p>
      <form id="connect">
        <label for="base">Proxy URL</label>
        <input id="base" type="url" required placeholder="http://127.0.0.1:8317" value="${escapeAttr(state.status.baseUrl || "http://127.0.0.1:8317")}" />
        <label for="mgmt">Management key</label>
        <input id="mgmt" type="password" required placeholder="management.secret-key" autocomplete="off" />
        <div class="choice" style="margin-top:14px">
          <button class="btn primary" type="submit" ${state.busy ? "disabled" : ""}>Connect</button>
          <button class="btn" type="button" id="disconnect">Disconnect</button>
        </div>
      </form>
    </section>
    <section class="panel">
      <h2>What already exists</h2>
      <p class="help">The stock page is <a href="https://github.com/router-for-me/Cli-Proxy-API-Management-Center">Cli-Proxy-API-Management-Center</a>, which ships inside CLIProxy as <code>/management.html</code>. Theo said his copy is an extensive private fork of VibeProxy and will not match a fresh install. Public quota tools (Quotio, Infinitus, CLIProxy Quota Tray, quota-reset-router) cover pieces of this. None of them is that fork. This console is the local board for the windows he was pointing at: 7-day, 5-hour, the dimmed extra bucket, and soonest-reset routing.</p>
    </section>
  `;
}

function bind() {
  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      state.filter = button.dataset.filter;
      render();
    });
  });
  document.getElementById("refresh")?.addEventListener("click", loadBoard);
  document.getElementById("reload-logs")?.addEventListener("click", loadLogs);
  document.getElementById("soonest")?.addEventListener("click", () => saveRouting("soonest"));
  document.getElementById("even")?.addEventListener("click", () => saveRouting("even"));
  document.getElementById("ws-on")?.addEventListener("click", () => saveRouting("sockets", true));
  document.getElementById("ws-off")?.addEventListener("click", () => saveRouting("sockets", false));
  document.getElementById("client-key")?.addEventListener("change", (event) => {
    state.clientKey = event.target.value;
    localStorage.setItem("cliproxy-console-client-key", state.clientKey);
    render();
  });
  document.getElementById("connect")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    state.busy = true;
    state.error = "";
    render();
    const response = await fetch("/api/settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        baseUrl: document.getElementById("base").value,
        managementKey: document.getElementById("mgmt").value,
      }),
    });
    const body = await response.json();
    state.busy = false;
    if (!response.ok) {
      state.error = body.error || "Connect failed";
      state.page = "proxy";
      render();
      return;
    }
    state.status = body;
    state.page = "quota";
    await loadBoard();
  });
  document.getElementById("disconnect")?.addEventListener("click", async () => {
    await fetch("/api/settings", { method: "DELETE" });
    state.status = { connected: false };
    state.board = sampleBoard();
    render();
  });
}

async function saveRouting(mode, websockets) {
  state.busy = true;
  state.routingNote = "";
  render();
  const response = await fetch("/api/routing", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ mode, websockets }),
  });
  const body = await response.json();
  state.busy = false;
  if (!response.ok) {
    state.routingNote = body.error || "Could not update routing";
  } else {
    const failed = (body.priorities || []).filter((item) => !item.ok);
    const socketNote = body.websockets?.length
      ? ` Websocket flag updated on ${body.websockets.length} Codex account(s).`
      : "";
    state.routingNote = body.warning
      || (mode === "sockets"
        ? `Websocket transport ${websockets ? "enabled" : "disabled"} for Codex auth files.${socketNote}`
        : `Strategy is now ${body.strategy}, session affinity is on.${failed.length ? ` ${failed.length} priority update(s) failed.` : ""}`);
    await loadBoard();
    return;
  }
  render();
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[char]));
}

function escapeAttr(value) {
  return escapeHtml(value);
}

await loadStatus();
await loadBoard();
