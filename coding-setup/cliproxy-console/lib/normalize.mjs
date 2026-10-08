/**
 * Pure helpers for the quota board.
 *
 * CLIProxy reports two clocks that matter, plus a third model-specific slice:
 *   weekly  — the 7-day pool. New sessions should prefer the account whose
 *             weekly window ends soonest, so leftover quota is used before it
 *             disappears.
 *   5-hour  — a burst cap inside that week. An empty 5-hour window means skip
 *             the account until it refills, even if the week still has room.
 *   extra   — a separate model bucket (Opus, or Codex's other window). Shown
 *             dimmed. It does not choose the account.
 */

const WEEKLY_KEYS = /seven[_\s-]?day|7d|weekly|secondary[_\s-]?window/i;
const FIVE_HOUR_KEYS = /five[_\s-]?hour|5h|primary[_\s-]?window/i;

export function maskName(name) {
  const raw = String(name ?? "");
  return raw.replace(/[A-Za-z0-9._%+-]+@/g, (match) => {
    const local = match.slice(0, -1);
    const dash = local.lastIndexOf("-");
    const head = dash >= 0 ? local.slice(0, dash + 1) : "";
    const person = dash >= 0 ? local.slice(dash + 1) : local;
    return `${head}${person.slice(0, 1)}•••@`;
  });
}

export function remainingFrom(value) {
  if (!value || typeof value !== "object") return null;
  if (typeof value.remaining_percent === "number") {
    return clampPercent(value.remaining_percent);
  }
  if (typeof value.remaining === "number" && value.remaining <= 1) {
    return clampPercent(value.remaining * 100);
  }
  if (typeof value.used_percent === "number") {
    return clampPercent(100 - value.used_percent);
  }
  if (typeof value.utilization === "number") {
    const used = value.utilization <= 1 ? value.utilization * 100 : value.utilization;
    return clampPercent(100 - used);
  }
  return null;
}

export function resetFrom(value) {
  if (!value || typeof value !== "object") return null;
  const direct =
    value.resets_at ||
    value.reset_at ||
    value.resetsAt ||
    value.resetAt ||
    null;
  if (typeof direct === "string" && !Number.isNaN(Date.parse(direct))) return direct;
  if (typeof direct === "number" && direct > 1_000_000_000) {
    const ms = direct < 10_000_000_000 ? direct * 1000 : direct;
    return new Date(ms).toISOString();
  }
  const seconds = value.reset_after_seconds ?? value.resetAfterSeconds;
  if (typeof seconds === "number" && seconds >= 0) {
    return new Date(Date.now() + seconds * 1000).toISOString();
  }
  return null;
}

function clampPercent(n) {
  if (!Number.isFinite(n)) return null;
  return Math.max(0, Math.min(100, Math.round(n * 10) / 10));
}

function slotFor(key, provider) {
  const name = String(key);
  // The gray column is the separate Opus slice. Check it before the weekly
  // pattern, because the key is often "seven_day_opus".
  if (/opus/i.test(name)) return "extra";
  if (provider === "codex") {
    if (/primary/i.test(name)) return "fiveHour";
    if (/secondary/i.test(name)) return "weekly";
  }
  if (FIVE_HOUR_KEYS.test(name) && !WEEKLY_KEYS.test(name)) return "fiveHour";
  if (WEEKLY_KEYS.test(name)) return "weekly";
  if (FIVE_HOUR_KEYS.test(name)) return "fiveHour";
  return null;
}

const SLOT_LABEL = {
  weekly: "7-day",
  fiveHour: "5-hour",
  extra: "Other bucket",
};

/**
 * Walk a usage payload and pull the three windows.
 * Only objects that themselves carry a utilization field count, so nested
 * wrappers are not double-counted.
 */
export function windowsFromUsage(provider, body) {
  const found = [];
  visit(body, (key, value) => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return;
    const remaining = remainingFrom(value);
    if (remaining == null) return;
    const slot = slotFor(key, provider);
    if (!slot) return;
    found.push({
      slot,
      label: slot === "extra" ? extraLabel(key) : SLOT_LABEL[slot],
      rawKey: String(key),
      remaining,
      resetsAt: resetFrom(value),
    });
  });

  const bySlot = new Map();
  for (const window of found) {
    if (!bySlot.has(window.slot)) bySlot.set(window.slot, window);
  }
  return ["weekly", "fiveHour", "extra"]
    .map((slot) => bySlot.get(slot))
    .filter(Boolean);
}

function extraLabel(key) {
  const text = String(key).replace(/[_-]+/g, " ");
  if (/opus/i.test(text)) return "Opus bucket";
  return "Other bucket";
}

const WINDOW_TITLES = {
  five_hour: ["Current session", "session", "fiveHour"],
  seven_day: ["Current week (all models)", "weekly", "weekly"],
  seven_day_sonnet: ["Current week (Sonnet only)", "weekly", "extra"],
  seven_day_opus: ["Current week (Opus only)", "weekly", "extra"],
  seven_day_oauth_apps: ["Current week (OAuth apps)", "weekly", "extra"],
  seven_day_cowork: ["Current week (Cowork)", "weekly", "extra"],
};

/**
 * The same buckets Claude Code prints for `/usage`.
 * `limits` is the categorized list (session, all-models week, Fable/Sonnet/Opus).
 * Top-level windows fill anything that list left out. Null buckets are omitted.
 */
export function usageReport(provider, body) {
  if (!body || typeof body !== "object") return { categories: [], extra: null };
  if (provider === "codex") return { categories: codexCategories(body), extra: null };
  return claudeReport(body);
}

function claudeReport(body) {
  const categories = [];
  const seen = new Set();

  if (Array.isArray(body.limits)) {
    for (const limit of body.limits) {
      const title = titleForLimit(limit);
      if (!title || seen.has(title) || typeof limit.percent !== "number") continue;
      seen.add(title);
      categories.push(categoryFromUsed({
        title,
        group: limit.group || "weekly",
        slot: slotForLimit(limit),
        used: limit.percent,
        resetsAt: typeof limit.resets_at === "string" ? limit.resets_at : null,
        active: limit.is_active !== false,
        severity: limit.severity || "normal",
      }));
    }
  }

  for (const [key, [title, group, slot]] of Object.entries(WINDOW_TITLES)) {
    if (seen.has(title)) continue;
    const value = body[key];
    if (!value || typeof value !== "object") continue;
    const remaining = remainingFrom(value);
    if (remaining == null) continue;
    seen.add(title);
    categories.push(categoryFromUsed({
      title,
      group,
      slot,
      used: 100 - remaining,
      resetsAt: resetFrom(value),
      active: true,
      severity: "normal",
    }));
  }

  const order = { fiveHour: 0, weekly: 1, extra: 2 };
  categories.sort((a, b) => (order[a.slot] ?? 9) - (order[b.slot] ?? 9) || a.title.localeCompare(b.title));
  return { categories, extra: extraUsageFrom(body.extra_usage) };
}

function titleForLimit(limit) {
  if (limit?.kind === "session") return "Current session";
  if (limit?.kind === "weekly_all") return "Current week (all models)";
  if (limit?.kind === "weekly_scoped") {
    const name = limit.scope?.model?.display_name || limit.scope?.model?.id;
    return name ? `Current week (${name})` : "Current week (scoped)";
  }
  return null;
}

function slotForLimit(limit) {
  if (limit?.kind === "session") return "fiveHour";
  if (limit?.kind === "weekly_all") return "weekly";
  return "extra";
}

function categoryFromUsed({ title, group, slot, used, resetsAt, active, severity }) {
  const usedPercent = clampPercent(used);
  return {
    title,
    group,
    slot,
    used: usedPercent,
    remaining: usedPercent == null ? null : clampPercent(100 - usedPercent),
    resetsAt: resetsAt || null,
    active: Boolean(active),
    severity: severity || "normal",
  };
}

function extraUsageFrom(value) {
  if (!value || typeof value !== "object") return null;
  const utilization = typeof value.utilization === "number" ? clampPercent(value.utilization <= 1 && value.utilization > 0 ? value.utilization * 100 : value.utilization) : null;
  return {
    enabled: Boolean(value.is_enabled),
    reason: typeof value.disabled_reason === "string" ? value.disabled_reason : "",
    spendLimitReached: Boolean(value.spend_limit_reached),
    utilization,
  };
}

function codexCategories(body) {
  return windowsFromUsage("codex", body).map((window) => categoryFromUsed({
    title: window.slot === "fiveHour" ? "Current session" : window.slot === "weekly" ? "Current week" : window.label,
    group: window.slot === "fiveHour" ? "session" : "weekly",
    slot: window.slot,
    used: 100 - window.remaining,
    resetsAt: window.resetsAt,
    active: true,
    severity: "normal",
  }));
}

/** Ranking still uses the all-models week and the session cap, not a model slice. */
export function windowsFromCategories(categories) {
  const picked = [];
  for (const slot of ["weekly", "fiveHour"]) {
    const match = (categories || []).find((item) => item.slot === slot && item.remaining != null);
    if (match) {
      picked.push({
        slot,
        label: match.title,
        remaining: match.remaining,
        resetsAt: match.resetsAt,
      });
    }
  }
  return picked;
}

function visit(node, fn, key = "") {
  if (!node || typeof node !== "object") return;
  if (!Array.isArray(node)) fn(key, node);
  for (const [childKey, child] of Object.entries(node)) {
    if (child && typeof child === "object") visit(child, fn, childKey);
  }
}

export function parseUsageBody(text) {
  if (text == null || text === "") return null;
  if (typeof text === "object") return text;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

export function filesFromList(json) {
  if (!json) return [];
  if (Array.isArray(json)) return json;
  for (const key of ["files", "credentials", "items"]) {
    if (Array.isArray(json[key])) return json[key];
  }
  return [];
}

export function providerOf(file) {
  const provider = String(file?.provider || file?.type || "").toLowerCase();
  if (provider) return provider;
  const name = String(file?.name || "").toLowerCase();
  if (name.startsWith("claude")) return "claude";
  if (name.startsWith("codex")) return "codex";
  if (name.includes("kimi")) return "kimi";
  if (name.includes("grok") || name.includes("xai")) return "xai";
  if (name.includes("antigravity")) return "antigravity";
  return "other";
}

export function decorateAccount(file, windows, extras = {}) {
  const weekly = windows.find((item) => item.slot === "weekly") || null;
  const fiveHour = windows.find((item) => item.slot === "fiveHour") || null;
  const exhausted =
    (weekly?.remaining === 0) || (fiveHour?.remaining === 0);
  const resetMs = weekly?.resetsAt ? Date.parse(weekly.resetsAt) : NaN;
  const email = String(file?.email || file?.label || extras.email || "");
  const plan = extras.plan || file?.subscription_type || "";
  const tier = CLAUDE_TIERS[extras.tier] || null;
  return {
    name: String(file?.name || file?.id || "account"),
    displayName: email || maskName(file?.name || file?.id || "account"),
    email,
    organization: extras.organization || "",
    provider: providerOf(file),
    authIndex: file?.auth_index || file?.authIndex || "",
    plan: plan && plan !== "oauth" ? String(plan) : "",
    capacity: tier?.capacity ?? null,
    tierLabel: tier?.label ?? "",
    tierError: extras.tierError || "",
    accountType: accountTypeLabel({
      provider: providerOf(file),
      apiKey: extras.apiKey,
      tier: extras.tier,
      orgType: extras.orgType,
      plan: plan && plan !== "oauth" ? String(plan) : "",
    }),
    disabled: Boolean(file?.disabled),
    unavailable: Boolean(file?.unavailable),
    cooldownCount: Array.isArray(file?.cooldowns) ? file.cooldowns.length : 0,
    status: file?.disabled ? "off" : file?.unavailable ? "down" : file?.status || "ready",
    windows,
    categories: extras.categories || [],
    extraUsage: extras.extraUsage || null,
    exhausted,
    weeklyResetMs: Number.isFinite(resetMs) ? resetMs : null,
  };
}

/**
 * Weekly capacity of each Claude plan as a multiple of Pro, keyed by the
 * organization rate_limit_tier from the OAuth profile.
 */
export const CLAUDE_TIERS = {
  default_claude_ai: { capacity: 1, label: "Pro" },
  default_claude_pro: { capacity: 1, label: "Pro" },
  default_claude_max_5x: { capacity: 5, label: "Max 5x" },
  default_claude_max_20x: { capacity: 20, label: "Max 20x" },
};

/**
 * Share of the pooled weekly quota still left across a provider's accounts,
 * weighting each account's remaining percentage by its plan capacity. Two
 * Max 5x accounts at 0% and 50% left pool to 25%. Null when any counted
 * account has no weekly window or no known plan size, because the pool
 * cannot be sized then and a partial number would be wrong.
 */
export function pooledWeekly(accounts) {
  const pool = accounts.filter((account) => !account.disabled);
  const weeklyOf = (account) => account.windows.find((item) => item.slot === "weekly")?.remaining;
  if (!pool.length || pool.some((account) => !account.capacity || typeof weeklyOf(account) !== "number")) {
    return null;
  }
  const total = pool.reduce((sum, account) => sum + account.capacity, 0);
  const left = pool.reduce((sum, account) => sum + account.capacity * weeklyOf(account), 0);
  return Math.round(left / total);
}

const CLAUDE_ORG_TYPES = {
  claude_team: "Team",
  claude_enterprise: "Enterprise",
  claude_max: "Max",
  claude_pro: "Pro",
};

/**
 * Human label for what kind of login an account is: the Claude plan tier and
 * organization type, an API key, or the plan a provider reports. Unrecognised
 * values are shown as the provider sent them.
 */
export function accountTypeLabel({ provider, apiKey, tier, orgType, plan }) {
  if (apiKey) return "API key";
  if (provider === "claude") {
    const size = CLAUDE_TIERS[tier]?.label || tier || "";
    const org = CLAUDE_ORG_TYPES[orgType] || orgType || "";
    return [size, org].filter(Boolean).join(" · ") || plan || "";
  }
  return plan ? plan.charAt(0).toUpperCase() + plan.slice(1) : "";
}

export function orgTypeFromProfile(body) {
  const type = body?.organization?.organization_type;
  return typeof type === "string" ? type : "";
}

export function planFromUsage(provider, body) {
  const plan = provider === "codex" ? body?.plan_type : "";
  return typeof plan === "string" ? plan : "";
}

/** Why a Claude plan tier from the OAuth profile cannot be used, or "" when it can. */
export function tierProblem(tier) {
  if (!tier) return "profile response had no organization.rate_limit_tier";
  if (!CLAUDE_TIERS[tier]) return `unknown plan tier "${tier}"; add it to CLAUDE_TIERS`;
  return "";
}

/**
 * Everything that keeps a Claude pool from being computed: a failed usage or
 * profile call, a response without a 7-day window, an unrecognised plan tier.
 * Shown on the card so an Anthropic API change is loud, not a silent dash.
 */
export function poolProblems(accounts) {
  const problems = [];
  for (const account of accounts) {
    if (account.provider !== "claude" || account.disabled) continue;
    const who = account.displayName || account.name;
    if (account.quotaError) problems.push(`${who}: usage call failed (${account.quotaError})`);
    else if (!account.windows.some((item) => item.slot === "weekly")) {
      problems.push(`${who}: usage response had no 7-day window`);
    }
    if (account.tierError) problems.push(`${who}: ${account.tierError}`);
  }
  return problems;
}

/** "2 × Max 5x" style description of the accounts that make up the pool. */
export function poolLabel(accounts) {
  const counts = new Map();
  for (const account of accounts.filter((item) => !item.disabled && item.tierLabel)) {
    counts.set(account.tierLabel, (counts.get(account.tierLabel) || 0) + 1);
  }
  return [...counts.entries()].map(([label, count]) => `${count} × ${label}`).join(" + ");
}

/**
 * Accounts that still have both the weekly and 5-hour windows open, ordered
 * by the soonest weekly reset. That first account is where a new session goes
 * when routing is set to fill-first.
 */
export function rankForSoonestReset(accounts) {
  return [...accounts].sort((a, b) => {
    if (a.exhausted !== b.exhausted) return a.exhausted ? 1 : -1;
    const aReset = a.weeklyResetMs ?? Number.POSITIVE_INFINITY;
    const bReset = b.weeklyResetMs ?? Number.POSITIVE_INFINITY;
    if (aReset !== bReset) return aReset - bReset;
    return a.name.localeCompare(b.name);
  });
}

export function prioritiesFor(accounts) {
  const ranked = rankForSoonestReset(accounts).filter((account) => !account.disabled);
  return ranked.map((account, index) => ({
    name: account.name,
    priority: Math.max(1, 100 - index * 10),
    preferred: index === 0 && !account.exhausted && account.weeklyResetMs != null,
  }));
}

/**
 * Rewrite only the routing strategy and session-affinity lines.
 * Leaves every other key, including anything under `codex:`, untouched.
 */
export function patchRoutingYaml(yaml, { strategy, sessionAffinity }) {
  const text = String(yaml ?? "");
  if (/^routing:[ \t]+\S/m.test(text)) {
    return { ok: false, reason: "inline-routing", yaml: text };
  }
  const lines = text.split("\n");
  let inRouting = false;
  let sawStrategy = false;
  let sawAffinity = false;
  const out = [];

  for (const line of lines) {
    if (/^routing:\s*$/.test(line)) {
      inRouting = true;
      out.push(line);
      continue;
    }
    if (inRouting && line.trim() !== "" && !/^\s/.test(line)) {
      if (!sawStrategy) out.push(`  strategy: "${strategy}"`);
      if (!sawAffinity) out.push(`  session-affinity: ${Boolean(sessionAffinity)}`);
      sawStrategy = true;
      sawAffinity = true;
      inRouting = false;
    }
    if (inRouting && /^\s+strategy:/.test(line)) {
      out.push(`  strategy: "${strategy}"`);
      sawStrategy = true;
      continue;
    }
    if (inRouting && /^\s+session-affinity:/.test(line)) {
      out.push(`  session-affinity: ${Boolean(sessionAffinity)}`);
      sawAffinity = true;
      continue;
    }
    out.push(line);
  }

  if (inRouting) {
    if (!sawStrategy) out.push(`  strategy: "${strategy}"`);
    if (!sawAffinity) out.push(`  session-affinity: ${Boolean(sessionAffinity)}`);
  }

  if (!/^routing:\s*$/m.test(text)) {
    const addition = [
      "",
      "routing:",
      `  strategy: "${strategy}"`,
      `  session-affinity: ${Boolean(sessionAffinity)}`,
      `  session-affinity-ttl: "1h"`,
      "",
    ];
    return { ok: true, appended: true, yaml: `${text.replace(/\s*$/, "")}\n${addition.join("\n")}` };
  }

  return { ok: true, appended: false, yaml: out.join("\n") };
}

export function formatReset(iso, now = Date.now()) {
  if (!iso) return "reset time unknown";
  const ms = Date.parse(iso) - now;
  if (!Number.isFinite(ms)) return "reset time unknown";
  if (ms <= 0) return "reset due";
  const minutes = Math.round(ms / 60000);
  if (minutes < 90) return `in ${minutes} min`;
  const hours = Math.round(ms / 3600000);
  if (hours < 20) return `in ${hours} hour${hours === 1 ? "" : "s"}`;
  const days = Math.round(ms / 86400000);
  return `in ${days} day${days === 1 ? "" : "s"}`;
}

export const USAGE_URL = {
  claude: "https://api.anthropic.com/api/oauth/usage",
  codex: "https://chatgpt.com/backend-api/wham/usage",
};

export function profileRequest(provider) {
  if (provider !== "claude") return null;
  return {
    method: "GET",
    url: "https://api.anthropic.com/api/oauth/profile",
    header: {
      Authorization: "Bearer $TOKEN$",
      "anthropic-version": "2023-06-01",
      "anthropic-beta": "oauth-2025-04-20",
      Accept: "application/json",
    },
  };
}

export function tierFromProfile(body) {
  const tier = body?.organization?.rate_limit_tier;
  return typeof tier === "string" ? tier : "";
}

export function usageRequest(provider) {
  const url = USAGE_URL[provider];
  if (!url) return null;
  const header = { Authorization: "Bearer $TOKEN$" };
  if (provider === "claude") {
    header["anthropic-version"] = "2023-06-01";
    header["anthropic-beta"] = "oauth-2025-04-20";
    header.Accept = "application/json";
  }
  return { method: "GET", url, header };
}
