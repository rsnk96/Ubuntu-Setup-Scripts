/**
 * Local consumption totals for clients that do not share Claude's /usage windows.
 * Numbers come from each app's own session store or account API. They are not
 * turned into a fake 5-hour bar.
 */

export function formatCount(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "—";
  const abs = Math.abs(n);
  if (abs >= 1_000_000_000) return `${trim(n / 1_000_000_000)}B`;
  if (abs >= 1_000_000) return `${trim(n / 1_000_000)}M`;
  if (abs >= 10_000) return `${trim(n / 1_000)}K`;
  return String(Math.round(n));
}

export function formatDollars(cents) {
  const n = Number(cents);
  if (!Number.isFinite(n)) return "—";
  return `$${(n / 100).toFixed(2)}`;
}

function trim(n) {
  const text = n.toFixed(1);
  return text.endsWith(".0") ? text.slice(0, -2) : text;
}

export function parseOpenCodeModel(value) {
  if (value && typeof value === "object") {
    return {
      id: String(value.id || "unknown"),
      provider: String(value.providerID || value.provider || "opencode"),
    };
  }
  try {
    return parseOpenCodeModel(JSON.parse(String(value || "")));
  } catch {
    return { id: String(value || "unknown"), provider: "opencode" };
  }
}

/** Collapse OpenCode session rows into provider groups. Bedrock is split out. */
export function summarizeOpenCode(rows) {
  const buckets = new Map();
  for (const row of rows || []) {
    const model = parseOpenCodeModel(row.model);
    const provider = model.provider === "amazon-bedrock" ? "bedrock" : "opencode";
    const key = `${provider}\0${model.id}`;
    const current = buckets.get(key) || {
      provider,
      label: model.id,
      detail: model.provider,
      sessions: 0,
      input: 0,
      output: 0,
      reasoning: 0,
      cacheRead: 0,
      cost: 0,
    };
    current.sessions += Number(row.sessions) || 0;
    current.input += Number(row.input) || 0;
    current.output += Number(row.output) || 0;
    current.reasoning += Number(row.reasoning) || 0;
    current.cacheRead += Number(row.cacheRead) || 0;
    current.cost += Number(row.cost) || 0;
    buckets.set(key, current);
  }
  const opencode = [];
  const bedrock = [];
  for (const item of buckets.values()) {
    (item.provider === "bedrock" ? bedrock : opencode).push(item);
  }
  const byTokens = (a, b) => (b.input + b.output) - (a.input + a.output);
  opencode.sort(byTokens);
  bedrock.sort(byTokens);
  return { opencode, bedrock };
}

export function summarizeCodex(rows) {
  return (rows || [])
    .filter((row) => row.model && Number(row.tokens) > 0)
    .map((row) => ({
      label: String(row.model),
      detail: String(row.provider || "openai"),
      sessions: Number(row.sessions) || 0,
      tokens: Number(row.tokens) || 0,
    }))
    .sort((a, b) => b.tokens - a.tokens);
}

export function summarizeCursorEdits(rows) {
  return (rows || [])
    .filter((row) => row.model && row.model !== "default")
    .map((row) => ({
      label: String(row.model),
      edits: Number(row.edits) || 0,
    }))
    .sort((a, b) => b.edits - a.edits);
}

export function summarizeCursorPlan(summary) {
  const plan = summary?.individualUsage?.plan;
  if (!plan) return null;
  return {
    membership: String(summary.membershipType || "plan"),
    cycleStart: summary.billingCycleStart || null,
    cycleEnd: summary.billingCycleEnd || null,
    includedUsedCents: numberOrNull(plan.used),
    includedLimitCents: numberOrNull(plan.limit),
    bonusCents: numberOrNull(plan.breakdown?.bonus),
    autoPercent: numberOrNull(plan.autoPercentUsed),
    apiPercent: numberOrNull(plan.apiPercentUsed),
    onDemandEnabled: Boolean(summary.individualUsage?.onDemand?.enabled),
  };
}

function numberOrNull(value) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}
