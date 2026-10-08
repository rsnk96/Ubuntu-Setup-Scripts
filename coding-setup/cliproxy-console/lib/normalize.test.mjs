import assert from "node:assert/strict";
import test from "node:test";
import {
  accountTypeLabel,
  decorateAccount,
  filesFromList,
  formatReset,
  maskName,
  patchRoutingYaml,
  planFromUsage,
  poolLabel,
  poolProblems,
  pooledWeekly,
  tierProblem,
  prioritiesFor,
  rankForSoonestReset,
  usageReport,
  windowsFromCategories,
  windowsFromUsage,
} from "./normalize.mjs";

test("reads either the v8 credentials list or the v0 auth-file list", () => {
  assert.equal(filesFromList({ credentials: [{ name: "a.json" }] })[0].name, "a.json");
  assert.equal(filesFromList({ files: [{ name: "b.json" }] })[0].name, "b.json");
});

test("masks the local part of an auth-file email", () => {
  assert.equal(maskName("claude-alice@example.com.json"), "claude-a•••@example.com.json");
  assert.equal(maskName("codex-work.json"), "codex-work.json");
});

test("reads Claude windows and parks Opus in the gray column", () => {
  const windows = windowsFromUsage("claude", {
    five_hour: { utilization: 0, resets_at: "2026-10-05T18:00:00Z" },
    seven_day: { utilization: 0.32, resets_at: "2026-10-06T17:00:00Z" },
    seven_day_opus: { utilization: 0.8, resets_at: "2026-10-08T17:00:00Z" },
  });
  assert.deepEqual(
    windows.map((item) => [item.slot, item.remaining, item.label]),
    [
      ["weekly", 68, "7-day"],
      ["fiveHour", 100, "5-hour"],
      ["extra", 20, "Opus bucket"],
    ],
  );
});

test("categorizes Claude /usage limits the way the CLI labels them", () => {
  const report = usageReport("claude", {
    five_hour: { utilization: 3, resets_at: "2026-10-05T03:09:59Z" },
    seven_day: { utilization: 32, resets_at: "2026-10-10T17:59:59Z" },
    seven_day_opus: null,
    seven_day_sonnet: null,
    limits: [
      { kind: "session", group: "session", percent: 3, severity: "normal", resets_at: "2026-10-05T03:09:59Z", is_active: false },
      { kind: "weekly_all", group: "weekly", percent: 32, severity: "normal", resets_at: "2026-10-10T17:59:59Z", is_active: true },
      {
        kind: "weekly_scoped",
        group: "weekly",
        percent: 0,
        severity: "normal",
        resets_at: "2026-10-10T18:00:00Z",
        is_active: false,
        scope: { model: { display_name: "Fable" } },
      },
    ],
    extra_usage: { is_enabled: false, disabled_reason: "out_of_credits", utilization: null },
  });
  assert.deepEqual(
    report.categories.map((item) => [item.title, item.used, item.remaining, item.active]),
    [
      ["Current session", 3, 97, false],
      ["Current week (all models)", 32, 68, true],
      ["Current week (Fable)", 0, 100, false],
    ],
  );
  assert.equal(report.extra.enabled, false);
  assert.equal(report.extra.reason, "out_of_credits");
  assert.deepEqual(
    windowsFromCategories(report.categories).map((item) => item.slot),
    ["weekly", "fiveHour"],
  );
});

test("treats Claude utilization above 1 as percent used", () => {
  const windows = windowsFromUsage("claude", {
    five_hour: { utilization: 0, resets_at: "2026-10-05T18:00:00Z" },
    seven_day: { utilization: 39, resets_at: "2026-10-07T01:00:00Z" },
  });
  assert.equal(windows.find((item) => item.slot === "weekly").remaining, 61);
  assert.equal(windows.find((item) => item.slot === "fiveHour").remaining, 100);
});

test("reads Codex primary as 5-hour and secondary as weekly", () => {
  const windows = windowsFromUsage("codex", {
    rate_limit: {
      primary_window: { used_percent: 0, reset_at: "2026-10-05T01:00:00Z" },
      secondary_window: { used_percent: 83, reset_at: "2026-10-09T01:00:00Z" },
    },
  });
  assert.equal(windows.find((item) => item.slot === "fiveHour").remaining, 100);
  assert.equal(windows.find((item) => item.slot === "weekly").remaining, 17);
});

test("ranks the open account whose weekly window ends soonest", () => {
  const soon = decorateAccount({ name: "claude-a.json", provider: "claude" }, [
    { slot: "weekly", remaining: 68, resetsAt: "2026-10-05T17:00:00Z" },
    { slot: "fiveHour", remaining: 100, resetsAt: "2026-10-05T01:00:00Z" },
  ]);
  const later = decorateAccount({ name: "claude-b.json", provider: "claude" }, [
    { slot: "weekly", remaining: 100, resetsAt: "2026-10-08T17:00:00Z" },
    { slot: "fiveHour", remaining: 100, resetsAt: "2026-10-05T01:00:00Z" },
  ]);
  const empty = decorateAccount({ name: "claude-c.json", provider: "claude" }, [
    { slot: "weekly", remaining: 0, resetsAt: "2026-10-04T18:00:00Z" },
    { slot: "fiveHour", remaining: 100, resetsAt: "2026-10-05T01:00:00Z" },
  ]);
  const ranked = rankForSoonestReset([later, empty, soon]);
  assert.deepEqual(ranked.map((item) => item.name), [
    "claude-a.json",
    "claude-b.json",
    "claude-c.json",
  ]);
  const priorities = prioritiesFor([later, empty, soon]);
  assert.equal(priorities[0].name, "claude-a.json");
  assert.equal(priorities[0].priority, 100);
  assert.equal(priorities[0].preferred, true);
  assert.equal(priorities.at(-1).name, "claude-c.json");
});

test("routing patch changes strategy and affinity only", () => {
  const original = [
    "port: 8317",
    "routing:",
    '  strategy: "round-robin"',
    "  session-affinity: false",
    '  session-affinity-ttl: "1h"',
    "codex:",
    "  identity-confuse: false",
    "  disable-codex-cloaking: false",
    "",
  ].join("\n");
  const patched = patchRoutingYaml(original, {
    strategy: "fill-first",
    sessionAffinity: true,
  });
  assert.equal(patched.ok, true);
  assert.match(patched.yaml, /strategy: "fill-first"/);
  assert.match(patched.yaml, /session-affinity: true/);
  assert.match(patched.yaml, /identity-confuse: false/);
  assert.match(patched.yaml, /disable-codex-cloaking: false/);
  assert.doesNotMatch(patched.yaml, /round-robin/);
});

test("refuses to rewrite an inline routing line", () => {
  const result = patchRoutingYaml('routing: { strategy: "round-robin" }\n', {
    strategy: "fill-first",
    sessionAffinity: true,
  });
  assert.equal(result.ok, false);
  assert.equal(result.reason, "inline-routing");
});

test("describes a reset that is a day away", () => {
  const now = Date.parse("2026-10-04T17:00:00Z");
  assert.equal(formatReset("2026-10-05T17:00:00Z", now), "in 1 day");
  assert.equal(formatReset("2026-10-08T17:00:00Z", now), "in 4 days");
});

test("pools weekly quota across accounts weighted by plan capacity", () => {
  const account = (remaining, tier, extra = {}) =>
    decorateAccount({ name: `a${remaining}`, type: "claude", ...extra }, [{ slot: "weekly", remaining }], { tier });
  const max5 = "default_claude_max_5x";
  assert.equal(pooledWeekly([account(0, max5, { unavailable: true }), account(50, max5)]), 25);
  assert.equal(pooledWeekly([account(0, max5), account(50, "default_claude_max_20x")]), 40);
  assert.equal(pooledWeekly([account(80, max5), account(50, max5, { disabled: true })]), 80);
  assert.equal(poolLabel([account(0, max5), account(50, max5)]), "2 × Max 5x");
});

test("pooled weekly quota is unknown when an account's plan size is unknown", () => {
  const account = (remaining, tier) =>
    decorateAccount({ name: "a", type: "claude" }, [{ slot: "weekly", remaining }], { tier });
  assert.equal(pooledWeekly([account(0, "default_claude_max_5x"), account(50, "")]), null);
  assert.equal(pooledWeekly([]), null);
});

test("pooled weekly quota is unknown when an enabled account returned no weekly window", () => {
  const withWindow = decorateAccount({ name: "a", type: "claude" }, [{ slot: "weekly", remaining: 50 }], { tier: "default_claude_max_5x" });
  const without = decorateAccount({ name: "b", type: "claude" }, [], { tier: "default_claude_max_5x" });
  assert.equal(pooledWeekly([withWindow, without]), null);
  assert.equal(pooledWeekly([withWindow, { ...without, disabled: true }]), 50);
});

test("reports every reason a Claude pool cannot be computed", () => {
  const ok = decorateAccount({ name: "ok", type: "claude", email: "ok@example.com" }, [{ slot: "weekly", remaining: 50 }], { tier: "default_claude_max_5x" });
  assert.deepEqual(poolProblems([ok]), []);
  const failed = { ...ok, displayName: "failed@example.com", windows: [], quotaError: "usage endpoint returned 401" };
  const shapeChange = { ...ok, displayName: "shape@example.com", windows: [{ slot: "fiveHour", remaining: 90 }] };
  const badTier = { ...ok, displayName: "tier@example.com", tierError: tierProblem("default_claude_max_50x") };
  assert.deepEqual(poolProblems([failed, shapeChange, badTier]), [
    "failed@example.com: usage call failed (usage endpoint returned 401)",
    "shape@example.com: usage response had no 7-day window",
    'tier@example.com: unknown plan tier "default_claude_max_50x"; add it to CLAUDE_TIERS',
  ]);
  assert.deepEqual(poolProblems([{ ...failed, disabled: true }]), []);
  assert.deepEqual(poolProblems([{ ...failed, provider: "codex" }]), []);
});

test("tierProblem accepts known tiers and rejects empty or unknown ones", () => {
  assert.equal(tierProblem("default_claude_max_20x"), "");
  assert.match(tierProblem(""), /no organization\.rate_limit_tier/);
  assert.match(tierProblem("brand_new_tier"), /unknown plan tier/);
});

test("labels what kind of login each account is", () => {
  assert.equal(accountTypeLabel({ provider: "claude", tier: "default_claude_max_5x", orgType: "claude_team" }), "Max 5x · Team");
  assert.equal(accountTypeLabel({ provider: "claude", tier: "default_claude_max_20x", orgType: "claude_enterprise" }), "Max 20x · Enterprise");
  assert.equal(accountTypeLabel({ provider: "claude", tier: "future_tier", orgType: "claude_new" }), "future_tier · claude_new");
  assert.equal(accountTypeLabel({ provider: "claude", apiKey: true }), "API key");
  assert.equal(accountTypeLabel({ provider: "codex", plan: "plus" }), "Plus");
  assert.equal(accountTypeLabel({ provider: "codex" }), "");
  assert.equal(planFromUsage("codex", { plan_type: "pro" }), "pro");
  assert.equal(planFromUsage("claude", { plan_type: "pro" }), "");
});
